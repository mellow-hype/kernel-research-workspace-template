NPROCS := $(shell expr $(shell nproc) - 2)
KSRC_BASE=kernel-src
DEVENV_BASE := $(PWD)/res/dev-env
KUTILS := ./kutils
KUTILS_DEBOOTSTRAPPER := $(KUTILS)/debootstrapper
KUTILS_KERNEL_DL := $(KUTILS)/build-utils/kerneldl.sh
KUTILS_CONFIG_BASELINE := $(KUTILS)/config/config-x86-baseline.sh
KUTILS_CONFIG_DEBUG := $(KUTILS)/config/config-debugflags.sh
KUTILS_CONFIG_KCOV := $(KUTILS)/config/config-kcov.sh
KUTILS_CONFIG_FUZZING := $(KUTILS)/config/config-fuzzing.sh
LINUX_ARCHIVE=linux-$(version).tar.gz
VIRT_DIR ?= ./virt
TIMESTAMP := $(shell date +%Y%m%d-%H%M%S)
WORKSPACE_DIRS := analysis fuzzing $(KSRC_BASE) dev/experiments dev/exploits res/data

ifdef ksrc
VIRT_EXPORT_DIR_X86 := $(VIRT_DIR)/kernels/$(shell basename $(ksrc))_x86_64
endif

ifndef dldir
dldir := $(KSRC_BASE)
endif

# Validation targets
fail_if_not_in_docker:
	if [ ! -f /.dockerenv ]; then echo "This target should be run inside a builder container (e.g. first do 'make dock_focal')"; exit 1; fi

version_check:
ifndef version
	$(error version is not set. Usage: 'make version=<kernel-version> $@')
	exit 1
endif

dev_env_check:
ifndef env
	$(error env is not set. Usage: 'make env=env-name $@')
	exit 1
endif

mnt_check:
ifndef mnt
	$(error mnt is not set. Usage: 'make mnt=path/to/mountpoint $@')
	exit 1
endif
	if [ ! -d $(mnt) ]; then echo "Directory $(mnt) does not exist."; exit 1; fi

ksrc_check:
ifndef ksrc
	$(error ksrc is not set. Usage: 'make ksrc=path/to/kernel $@')
	exit 1
endif
	if [ ! -d $(ksrc) ]; then echo "Directory $(ksrc) does not exist"; exit 1; fi

build_tag_check:
ifndef tag
	$(error tag is not set. Usage: 'make tag=tag $@')
	exit 1
endif

odir_check:
ifndef odir
	$(error odir is not set. Usage: 'make odir=output/dir <...> $@')
	exit 1
endif

qemu_run_check:
ifndef kernel
	$(error kernel is not set. Usage: 'make kernel=path/to/kernel/image rootfs=path/to/rootfs $@')
	exit 1
endif
ifndef rootfs
	$(error rootfs is not set. Usage: 'make kernel=path/to/kernel/image rootfs=path/to/rootfs $@')
	exit 1
endif

# Initialization targets
init_all: init_workspace init_docker_kbuilders init_docker_debootstrap init_docker_dev_env
	$(info Full workspace initialization complete)

init_workspace:
	mkdir -p $(WORKSPACE_DIRS)
	make -C $(VIRT_DIR) init_dirs
	$(info Workspace directories created successfully)

# Utility targets
help:
	$(info Makefile targets:)
	$(info -----------------)
	$(info help | Show this help message)
	$(info download version=<kver> [dldir=output/dir] | Download and extract specified kernel version)
	$(info init_all | Initialize entire workspace (dirs, docker build containers, debootstrap containers, dev env))
	$(info init_workspace | Create workspace directories)
	$(info -----------------)
	$(info init_docker_debootstrap | Initialize docker debootstrap containers and utilities)
	$(info build_rootfs_bullseye odir=output/dir | Build Debian Bullseye rootfs in output/dir)
	$(info build_rootfs_buster odir=output/dir | Build Debian Buster rootfs in output/dir)
	$(info build_rootfs_sid odir=output/dir | Build Debian Sid rootfs in output/dir)
	$(info -----------------)
	$(info init_docker_kbuilders | Initialize docker kernel builder containers)
	$(info dock_kbuild_bionic | Run Ubuntu 18.04 docker container for kernel building)
	$(info dock_kbuild_focal | Run Ubuntu 20.04 docker container for kernel building)
	$(info dock_kbuild_jammy | Run Ubuntu 22.04 docker container for kernel building)
	$(info -----------------)
	$(info config_x86 ksrc=path/to/kernel | Generate default x86_64 config at ksrc/.config)
	$(info config_baseline ksrc=path/to/kernel | Apply baseline config flags to ksrc/.config)
	$(info config_debug ksrc=path/to/kernel | Apply debug config flags to ksrc/.config)
	$(info config_kcov ksrc=path/to/kernel | Apply kcov config flags to ksrc/.config)
	$(info config_fuzzing ksrc=path/to/kernel | Apply fuzzing config flags to ksrc/.config)
	$(info -----------------)
	$(info compile ksrc=path/to/kernel | Compile kernel at ksrc)
	$(info build_default ksrc=path/to/kernel | Full clean, config, and build of kernel at ksrc)
	$(info build_default_debug ksrc=path/to/kernel | Full clean, config + debug, and build of kernel at ksrc)
	$(info build_default_kcov ksrc=path/to/kernel | Full clean, config + kcov, and build of kernel at ksrc)
	$(info build_default_fuzzing ksrc=path/to/kernel | Full clean, config + fuzzing, and build of kernel at ksrc)
	$(info -----------------)
	$(info ksrc_full_clean ksrc=path/to/kernel | Run 'make mrproper' and 'make distclean' in ksrc)
	$(info ksrc_clone ksrc=path/to/kernel tag=tag odir=output/dir | Clone kernel source at ksrc to odir/kernel-src-tag)
	$(info -----------------)
	$(info export_kernel_x86 ksrc=path/to/kernel | Export kernel image and defconfig to virt/kernels)
	$(info qemu_run kernel=path/to/kernel/image rootfs=path/to/rootfs.img | Run specified kernel and rootfs in QEMU)
	$(info -----------------)
	$(info init_docker_dev_env | Initialize docker development environment containers)
	$(info dev_env env=env-name mnt=path/to/mountpoint | Run specified development environment container with mount)
	$(info -----------------)

download: version_check init_workspace
	test -e $(dldir)/$(LINUX_ARCHIVE) || $(KUTILS_KERNEL_DL) $(version) $(dldir)/.
	$(info kernel source archive: $(dldir)/$(LINUX_ARCHIVE))
	tar xvzf $(dldir)/linux-$(version).tar.gz -C $(dldir)/.
	$(info kernel source extracted to $(dldir)/linux-$(version))

ksrc_full_clean: ksrc_check
	$(info Cleaning kernel at $(ksrc))
	make -C $(ksrc) mrproper
	make -C $(ksrc) distclean
	rm -rf $(ksrc)/.config
	rm -rf $(ksrc)/Module.symvers
	rm -rf $(ksrc)/modules.order
	rm -rf $(ksrc)/.tmp_versions

ksrc_clone: ksrc_check build_tag_check odir_check
	$(info Cloning kernel source at $(ksrc) to $(odir)/$(shell basename $(ksrc))-$(tag))
	mkdir -p $(odir)
	cp -r $(ksrc) $(odir)/$(shell basename $(ksrc))-$(tag)

# Kernel builder container targets
init_docker_kbuilders:
	make -C $(KUTILS)/docker all
	$(info Docker build containers initialized successfully)

dock_kbuild_bionic:
	sudo docker run -v $(PWD)/:/home/builder/src --rm -it ubuntu18-kbuild-generic

dock_kbuild_focal:
	sudo docker run -v $(PWD)/:/home/builder/src --rm -it ubuntu20-kbuild-generic

dock_kbuild_jammy:
	sudo docker run -v $(PWD)/:/home/builder/src --rm -it ubuntu22-kbuild-generic

# Configuration targets
config_x86: ksrc_check
	$(info Generating default x86_64 config at $(ksrc)/.config)
	make -C $(ksrc) x86_64_defconfig

config_baseline: ksrc_check
	$(info Applying baseline flags to config at $(ksrc)/.config)
	$(KUTILS_CONFIG_BASELINE) $(ksrc)

config_debug: ksrc_check
	$(info Applying debug flags to config at $(ksrc)/.config)
	$(KUTILS_CONFIG_DEBUG) $(ksrc)

config_kcov: ksrc_check config_debug
	$(info Applying kcov flags to config at $(ksrc)/.config)
	$(KUTILS_CONFIG_KCOV) $(ksrc)

config_fuzzing: ksrc_check config_kcov
	$(info Applying fuzzing flags to config at $(ksrc)/.config)
	$(KUTILS_CONFIG_FUZZING) $(ksrc)

# Build targets
compile: ksrc_check
	$(info Compiling kernel at $(ksrc) (nprocs=$(NPROCS)))
	cd $(ksrc) && make -j$(NPROCS)

build_default: ksrc_full_clean config_x86 config_baseline compile
	$(info Full default x86_x64 build complete)

build_default_debug: ksrc_full_clean config_x86 config_baseline config_debug compile
	$(info Full default +debug x86_x64 build complete)

build_default_kcov: ksrc_full_clean config_x86 config_baseline config_kcov compile
	$(info Full default +kcov+debug x86_x64 build complete)

build_default_fuzzing: ksrc_full_clean config_x86 config_baseline config_fuzzing compile
	$(info Full default +fuzzing+kcov+debug x86_x64 build complete)

# Export targets
export_kernel_x86: ksrc_check
	$(info Exporting kernel image from $(ksrc))
	mkdir -p $(VIRT_EXPORT_DIR_X86)
	make -C $(ksrc) savedefconfig
	cp -r $(ksrc)/defconfig $(VIRT_EXPORT_DIR_X86)/defconfig-$(TIMESTAMP)
	cp $(ksrc)/arch/x86/boot/bzImage $(VIRT_EXPORT_DIR_X86)/bzImage-$(TIMESTAMP)
	cp $(ksrc)/vmlinux $(VIRT_EXPORT_DIR_X86)/vmlinux-$(TIMESTAMP)

export_kernel_tagged: ksrc_check build_tag_check
	$(info Exporting kernel image from $(ksrc) with tag $(tag))
	mkdir -p $(VIRT_EXPORT_DIR_X86)
	make -C $(ksrc) savedefconfig
	cp -r $(ksrc)/defconfig $(VIRT_EXPORT_DIR_X86)/defconfig-$(tag)
	cp $(ksrc)/arch/x86/boot/bzImage $(VIRT_EXPORT_DIR_X86)/bzImage-$(tag)
	cp $(ksrc)/vmlinux $(VIRT_EXPORT_DIR_X86)/vmlinux-$(tag)

# Dev environment targets
init_docker_dev_env:
	make -C $(DEVENV_BASE) init

dev_env: mnt_check dev_env_check
ifeq ($(env),bullseye)
	$(info Running 'bullseye-dev' container with mount $(mnt))
	make -C $(DEVENV_BASE) run_bullseye mnt=$(mnt)
endif
ifeq ($(env),sid)
	$(info Running 'sid-dev' container with mount $(mnt))
	make -C $(DEVENV_BASE) run_sid mnt=$(mnt)
endif

# Rootfs targets
init_docker_debootstrap:
	make -C $(KUTILS_DEBOOTSTRAPPER) init_docker
	make -C $(KUTILS_DEBOOTSTRAPPER) install
	$(info Docker debootstrap containers and utilities initialized successfully)

build_rootfs_bullseye: odir_check
	make -C $(KUTILS_DEBOOTSTRAPPER) bullseye_amd64 odir=$(odir)
	$(info Rootfs build complete - output at $(odir)/bullseye_amd64)

build_rootfs_buster: odir_check
	make -C $(KUTILS_DEBOOTSTRAPPER) buster odir=$(odir)
	$(info Rootfs build complete - output at $(odir)/buster_amd64)

build_rootfs_sid: odir_check
	make -C $(KUTILS_DEBOOTSTRAPPER) sid odir=$(odir)
	$(info Rootfs build complete - output at $(odir)/sid_amd64)

# QEMU targets
qemu_run: qemu_run_check
	make -C $(VIRT_DIR) run_x86 kernel=$(kernel) rootfs=$(rootfs)

