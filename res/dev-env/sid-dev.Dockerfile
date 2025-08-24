# This Dockerfile is based on Debian Sid to match the application/library versions
# that will be used on target VM images using a Sid-based rootfs image. Custom code
# that is to be executed on inside the VM (e.g., kernel modules, custom utilities, etc.)
# should be compiled using this container to ensure compatibility.
FROM debian:sid-slim
ENV TZ=America/Los_Angeles
ENV TERM=xterm-256color
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install most common dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    tmux \
    neovim \
    build-essential \
    clang \
    clang-format \
    clangd \
    pkg-config \
    fzf \
    openssh-client \
    tar \
    unzip \
    rsync \
    fakeroot \
    bzip2 \
    git-core \
    gzip \
    lzop \
    gawk \
    gettext \
    wget \
    curl \
    sudo \
    cpio \
    bc \
    python3 \
    python3-dev \
    python3-venv \
    libelf-dev \
    libssl-dev \
    zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# add non-root user with passwordless sudo priv
RUN useradd -s /bin/bash -m sid-dev &&\
    echo 'sid-dev ALL=NOPASSWD: ALL' > /etc/sudoers.d/sid-dev
USER sid-dev

# Copy in tmux config
COPY ./tmux.conf /home/sid-dev/.tmux.conf

# Set up workspace
WORKDIR /home/sid-dev/src
VOLUME [ "/home/sid-dev/src" ]

ENTRYPOINT [ "/bin/bash" ]
