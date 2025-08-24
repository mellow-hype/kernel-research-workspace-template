# This Dockerfile is based on Debian bookworm to match the application/library versions
# that will be used on target VM images using a bookworm-based rootfs image. Custom code
# that is to be executed on inside the VM (e.g., kernel modules, custom utilities, etc.)
# should be compiled using this container to ensure compatibility.
FROM debian:bookworm-slim
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
RUN useradd -s /bin/bash -m bookworm-dev &&\
    echo 'bookworm-dev ALL=NOPASSWD: ALL' > /etc/sudoers.d/bookworm-dev
USER bookworm-dev

# Copy in tmux config
COPY ./tmux.conf /home/bookworm-dev/.tmux.conf

# Set up workspace
WORKDIR /home/bookworm-dev/src
VOLUME [ "/home/bookworm-dev/src" ]

ENTRYPOINT [ "/bin/bash" ]
