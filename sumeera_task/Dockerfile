# Base image — AWS Lambda Python 3.10
FROM public.ecr.aws/lambda/python:3.10

# Install dependencies needed by headless Chromium and tools like unzip, tar, xz
RUN yum install -y \
    libXcomposite \
    libXdamage \
    libXrandr \
    libXScrnSaver \
    libxkbcommon \
    libXext \
    libXfixes \
    libX11 \
    libXrender \
    libXtst \
    libdrm \
    gtk3 \
    gtk2 \
    alsa-lib \
    atk \
    at-spi2-atk \
    cups-libs \
    libgbm \
    pango \
    GConf2 \
    xz \
    unzip \
    wget \
    tar \
    curl \
    file \
    && ln -s /lib64/libudev.so.1 /lib64/libudev.so.0 \
    && yum clean all

# Install Python dependencies into Lambda task root
COPY requirements.txt ./
RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copy your Python script(s)
COPY my_script.py ${LAMBDA_TASK_ROOT}

# Set Lambda handler
CMD ["my_script.lambda_handler"]
