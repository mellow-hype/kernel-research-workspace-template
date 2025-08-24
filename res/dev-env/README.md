## dev-env

This directory contains Dockerfile for container images to be used for compiling custom code
that is to be executed on VMs using target kernels to ensure compatibility (e.g. library/application
versions). Each image is based on a Debian version corresponding to versions currently used
to generate the root filesystem images for the VMs. This should ensure a nearly 1:1 environment so
binaries compiled with these images can be easily transferred to the VM's over the network and executed
without issues.

### files

- `bullseye-dev.Dockerfile`: Dockerfile for a Debian Bullseye-based image.
- `sid-dev.Dockerfile`: Dockerfile for a Debian Sid-based image.
- `tmux.conf`: tmux configuration file to be copied into the images for easier terminal management.
