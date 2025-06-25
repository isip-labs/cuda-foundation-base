# Stage 1: Common foundation with all shared dependencies
FROM ubuntu:22.04 AS foundation

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget curl git build-essential cmake pkg-config \
    libssl-dev libffi-dev libjpeg-dev libpng-dev \
    libavcodec-dev libavformat-dev libswscale-dev \
    libavdevice-dev ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    conda clean -afy

# Create base environment with common packages
RUN conda create -n base python=3.10 -y && \
    conda run -n base pip install \
    numpy scipy pandas matplotlib scikit-learn \
    jupyter ipython gradio streamlit fastapi uvicorn \
    requests pillow opencv-python tqdm wandb tensorboard \
    && conda clean -afy

# Stage 2: CUDA Development base
FROM nvidia/cuda:12.1-devel-ubuntu22.04 AS cuda-devel
COPY --from=foundation /opt/conda /opt/conda
COPY --from=foundation /usr/local /usr/local
ENV PATH=/opt/conda/bin:$PATH
RUN conda run -n base pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
RUN conda run -n base pip install transformers accelerate flash-attn --no-build-isolation

# Stage 3: PyTorch optimized base  
FROM pytorch/pytorch:2.6.0-cuda12.1-cudnn9-devel AS pytorch-base
COPY --from=foundation /opt/conda/envs/base/lib/python3.10/site-packages /opt/conda/lib/python3.10/site-packages
RUN pip install gradio streamlit fastapi uvicorn wandb tensorboard

# Stage 4: Runtime base
FROM nvidia/cuda:12.1-runtime-ubuntu22.04 AS cuda-runtime
COPY --from=foundation /opt/conda /opt/conda
ENV PATH=/opt/conda/bin:$PATH
RUN conda run -n base pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121
