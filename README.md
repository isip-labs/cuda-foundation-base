# CUDA Foundation Base Images

Multi-stage Docker foundation for CUDA applications with shared dependencies.

## Overview

Creates specialized base images from a common foundation to reduce disk usage and build times across multiple CUDA applications.

## What's Included

**Foundation Stage:**
- Ubuntu 22.04
- Miniconda with Python 3.10
- System dependencies (ffmpeg, build tools)
- Common ML packages (numpy, pandas, matplotlib, etc.)
- Web frameworks (gradio, streamlit, fastapi)
- Development tools (jupyter, wandb, tensorboard)

**Specialized Stages:**
- `cuda-devel`: Full CUDA development toolkit + PyTorch
- `pytorch-base`: Optimized PyTorch container + common packages  
- `cuda-runtime`: Minimal runtime for inference

## Why Use This

- **Reduce disk usage**: Share 2-5GB of common dependencies
- **Faster builds**: Cached foundation layer
- **Consistency**: Same base environment across projects
- **Flexibility**: Choose appropriate specialization per app

## Build Instructions

```bash
# Build all variants
docker build --target cuda-devel -t my-cuda-devel:latest .
docker build --target pytorch-base -t my-pytorch:latest .
docker build --target cuda-runtime -t my-cuda-runtime:latest .
```

## Usage in Projects

### Local Projects

```dockerfile
# Training/development apps
FROM my-cuda-devel:latest
COPY . /app/
RUN conda run -n base pip install -r requirements.txt
CMD ["conda", "run", "-n", "base", "python", "app.py"]

# PyTorch-specific apps  
FROM my-pytorch:latest
COPY . /app/
RUN pip install -r requirements.txt
CMD ["python", "app.py"]

# Inference apps
FROM my-cuda-runtime:latest 
COPY . /app/
RUN conda run -n base pip install -r requirements.txt
CMD ["conda", "run", "-n", "base", "python", "serve.py"]
```

### Docker Compose GPU Support

```yaml
services:
  app:
    build: .
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

## External Projects

### Pull from Registry

If pushed to registry:
```dockerfile
FROM your-registry.com/my-cuda-devel:latest
```

### Share via Export/Import

```bash
# Export image
docker save my-cuda-devel:latest | gzip > cuda-devel-base.tar.gz

# Import on another machine
gunzip -c cuda-devel-base.tar.gz | docker load
```

## Choosing the Right Base

- **Development/Training**: `my-cuda-devel` (full CUDA toolkit)
- **PyTorch Apps**: `my-pytorch` (optimized PyTorch)
- **Inference Only**: `my-cuda-runtime` (minimal size)

## Version Management

```bash
# Tag with versions
docker tag my-cuda-devel:latest my-cuda-devel:v1.0
docker tag my-pytorch:latest my-pytorch:v1.0

# Use specific versions in Dockerfile
FROM my-cuda-devel:v1.0
```

## Updating Dependencies

Rebuild foundation when updating common packages:
```bash
docker build --no-cache --target cuda-devel -t my-cuda-devel:latest .
```

## Requirements

- NVIDIA GPU
- Docker with NVIDIA container runtime
- Compatible NVIDIA drivers (check with `nvidia-smi`)
