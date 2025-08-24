# linux kernel research and development workspace

## overview

This repository provides a workspace for Linux kernel research and development, including tools and scripts for building and testing custom Linux kernels, creating root filesystems, running virtual machines, and performing kernel fuzzing and analysis. The workspace is designed to facilitate experimentation with different kernel configurations, features, and vulnerabilities in a controlled environment.

### workspace structure

```
/ (workspace root)
|-- dev/experiments     # experimental code, PoCs, etc.
|-- dev/exploits        # exploit code, etc.
|-- kernel-src          # linux kernel source code
|-- kutils              # kernel utilities (scripts, etc.)
|-- fuzzing             # fuzzing-related code, corpora, etc.
|-- analysis            # analysis scripts, CodeQL queries+databases, etc.
|-- res/dev-env         # dockerfiles, scripts, etc. for setting up dev environment
|-- res/data            # sample data files, etc.
|-- virt                # kernel images, rootfs images, etc.
```

### prerequisites

Testing has been performed on Debian 12 (Bookworm) and NixOS 25.04 host systems, with some features only confirmed to work on Debian-based systems. In particular, the debootstrapper cross-compilation containers require a Debian-based host system to function as relied upon by the current tooling. Most features (cross-arch kernel builds, native rootfs builds, VM execution) should work on any Linux host system with Docker and other primary dependencies.

The primary dependencies that need to be installed on the host system are:
- `git`
- `make`
- `docker`
- `qemu`
    - `qemu-system-<arch>` (e.g. `qemu-system-arm` for cross-arch Docker containers and VMs)
    - `qemu-user-static` (for cross-arch Docker containers)
    - `binfmt-support` (for cross-arch Docker containers)


## setting up the workspace

Core components of the workspace include:
- kernel builder docker images
- debootstrap builder docker images
- dev environment docker images
- baseline directory structure
- build scripts and other utilities

### baseline initialization

Clone this repository to your local machine (including submodules) and initialize the workspace structure:

```bash
git clone --recurse-submodules <repo-url>
cd <repo-dir>

# initialize the baseline directory structure
make init_workspace
```

### initialize tools and environment

From the root of the cloned repository, run:

```bash
# build the kernel builder docker images
make init_docker_kbuilders

# build the debootstrap builder docker images
make init_docker_debootstrap

# build the dev environment docker images
make init_docker_dev_env
```

## usage

### kernel building

The process of building a kernel typically involves the following steps:
1. Download and extract the desired kernel source code version (if not already available locally)
2. Configure the kernel source code
3. Build the kernel

The Makefile provides targets to facilitate these steps.

```bash
# download and extract kernel version 5.15.10 to ./kernel-src/linux-5.15.10
make download version=5.15.10

# drop into a kernel builer container shell (remaining make commands should be run inside the container)
make dock_kbuild_focal

# configure the kernel source code (generates a default x86_64 config)
make config_x86 ksrc=./kernel-src/linux-5.15.10

# apply baseline config flags to the kernel config
make config_baseline ksrc=./kernel-src/linux-5.15.10

# other targets for config sets are also available, e.g.: kcov, debug, etc.
make config_kcov ksrc=./kernel-src/linux-5.15.10

# build the kernel
make compile ksrc=./kernel-src/linux-5.15.10
```

Alternatively, you can use the `build_default` target to perform a full clean, config, and build in one step:

```bash
# default build (clean, config, compile) for x86_64
make build_default ksrc=./kernel-src/linux-5.15.10

# default kcov and debug builds are also available
make build_default_kcov ksrc=./kernel-src/linux-5.15.10
make build_default_debug ksrc=./kernel-src/linux-5.15.10
```

### building root filesystems with debootstrapper containers

The Makefile provides targets to facilitate building a root filesystem using the debootstrap Docker containers provided by `kutils/debootstrapper`. These containers use `debootstrap` to create minimal Debian-based root filesystems for use with QEMU.

Run the following commands from the root of the cloned repository to build minimal Debian root filesystems (_note: these make targets must be run outside of any Docker container_):

```bash
# build a minimal Debian Bullseye root filesystem at ./virt/rootfs/bullseye_amd64
make build_rootfs_bullseye odir=$PWD/virt/rootfs

# build a minimal Debian Buster root filesystem at ./virt/rootfs/buster_amd64
make build_rootfs_buster odir=$PWD/virt/rootfs

# build a minimal Debian Sid root filesystem at ./virt/rootfs/sid_amd64
make build_rootfs_sid odir=$PWD/virt/rootfs
```

The generated filesystems will use the ext4 format and will be located in the specified output directory (e.g. `./virt/rootfs/bullseye_amd64`).

The Makefile in `kutils/debootstrapper/Makefile` also provides a number of other targets for building different Debian releases and architectures. The containers can also be used directly to build custom root filesystems (the entrypoint will execute the `create-image-debian.sh` script, a modified version of the script used by `syzkaller`).

### running kernels with QEMU

The Makefile provides targets to facilitate running a built kernel with QEMU. This requires a built kernel image and a root filesystem.

```bash
# run a built kernel with QEMU using the specified kernel image and root filesystem
make qemu_run kernel=$PWD/virt/kernels/linux-5.15.10/bzImage rootfs=$PWD/virt/rootfs/bullseye_amd64/bullseye_amd64.img
```

_NOTE: The `qemu_run` target calls `make` in the `virt` directory, so ensure paths to the kernel and rootfs images are either absolute paths or paths relative to `virt`._

The Makefile at `virt/Makefile` also provides a number of other targets for running and interacting the VMs. Run `make help` in the `virt` directory to see the available targets.

### using the dev environment containers

The workspace includes Dockerfiles that can be used to create development environment containers with common tools and dependencies for kernel development, analysis, fuzzing, etc. This is important for ensuring a consistent environment across different host systems and for compatibility with the library versions be running on the VMs. The dev environment containers should be used for building code that will be executed on the VMs, such as kernel modules, fuzzers, analysis tools, etc., rather than building and running these tools directly on the host system or the VM. These containers are based on Debian versions which correspond to the root filesystems that are built with the debootstrapper containers, so this should come pretty close to being identical environments. The compiled binaries can then be copied to the VM for execution without worrying about library version mismatches.

To build and use the dev environment containers, run the following commands from the root of the cloned repository:

```bash
# build the dev environment docker images
make init_docker_dev_env
```

You can then run a container with the desired environment:

```bash
# run a dev environment container with the specified environment (e.g. bullseye)
make dev_env env=bullseye mnt=$PWD
```

NOTE: Any additional tools or dependencies that are installed into the dev environment containers should also be installed into the corresponding VM root filesystem to ensure compatibility. This can be done by chrooting into the root filesystem image and installing the packages, or by using `apt-get` in the running VM to install the packages directly.