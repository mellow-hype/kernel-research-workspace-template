
ROOTFS_BASE := $(PWD)/rootfs
DEFAULT_ROOTFS_BULLSEYE := $(ROOTFS_BASE)/bullseye-amd64
DEFAULT_ROOTFS_BULLSEYE_ORIG := $(DEFAULT_ROOTFS_BULLSEYE)/bullseye_amd64.ORIG.img
DEFAULT_SSH_KEY := $(DEFAULT_ROOTFS_BULLSEYE)/bullseye_amd64.id_rsa

# QEMU constants
QEMU_X86 := qemu-system-x86_64
QEMU_ARM64 := qemu-system-aarch64
QEMU_SSH_PORT ?= 10022
QEMU_FLAGS := -m 2G -smp 2 -enable-kvm -nographic
QEMU_NETWORK_DEFAULT := -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:$(QEMU_SSH_PORT)-:22
QEMU_NETWORK_DEVICE := -net nic,model=e1000
KERNEL_BOOTLINE := "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0 nokaslr"
KERNEL_BOOTLINE_RO := "console=ttyS0 root=/dev/sda ro earlyprintk=serial net.ifnames=0 nokaslr"
SSH_FLAGS := -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

ifndef clone_src
DEFAULT_ROOTFS := $(shell dirname $(DEFAULT_ROOTFS_BULLSEYE_ORIG))
DEFAULT_ROOTFS_ORIG := $(DEFAULT_ROOTFS_BULLSEYE_ORIG)
TAGGED_ROOTFS := $(ROOTFS_BASE)/$(tag)-$(shell basename $(DEFAULT_ROOTFS_ORIG) | cut -d. -f1).img
else
DEFAULT_ROOTFS := $(shell dirname $(clone_src))
DEFAULT_ROOTFS_ORIG := $(clone_src)
TAGGED_ROOTFS := $(ROOTFS_BASE)/$(tag)-$(shell basename $(clone_src) | cut -d. -f1).img
endif

src_dst_check:
ifndef src
	$(error src is not set. Usage: 'make src=path/to/file dst=/path/on/target $@')
	exit 1
endif
ifndef dst
	$(error dst is not set. Usage: 'make src=path/to/file dst=/path/on/target $@')
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

sshkey_check:
ifndef sshkey
	$(info sshkey is not set. Using default: $(DEFAULT_SSH_KEY))
sshkey := $(DEFAULT_SSH_KEY)
endif

help:
	$(info Makefile targets and usage:)
	$(info -----------------)
	$(info init_dirs | Initialize virt directories (kernels, rootfs))
	$(info clone_rootfs tag=tag | Clone default rootfs to create new rootfs with specified tag)
	$(info -----------------)
	$(info connect_remote [sshkey=path/to/key] | Connect to running QEMU instance via SSH (default key: $(DEFAULT_SSH_KEY)))
	$(info copy_to_target src=path/to/file dst=/path/on/target [sshkey=path/to/key] | Copy file to running QEMU instance via SCP)
	$(info copy_from_target src=/path/on/target dst=path/to/file [sshkey=path/to/key] | Copy file from running QEMU instance via SCP)
	$(info -----------------)
	$(info run_x86 kernel=path/to/kernel/image rootfs=path/to/rootfs | Run specified kernel and rootfs in QEMU)
	$(info -----------------)

clone_rootfs:
ifndef tag
	$(error tag is not set. Usage: 'make tag=tag $@')
	exit 1
endif
	$(info Cloning default rootfs $(DEFAULT_ROOTFS_ORIG) to create rootfs with tag $(tag))
	cp -a $(DEFAULT_ROOTFS_ORIG) $(TAGGED_ROOTFS)
	chmod u+w $(TAGGED_ROOTFS)
	ln -sf $(DEFAULT_ROOTFS)/bullseye_amd64.id_rsa $(ROOTFS_BASE)/$(tag).id_rsa

init_dirs:
	mkdir -p kernels rootfs
	$(info Initialization complete - created 'kernels' and 'rootfs' directories)

run_x86: qemu_run_check
	$(QEMU_X86) $(QEMU_FLAGS) \
		-cpu host \
		-kernel $(kernel) \
		-append $(KERNEL_BOOTLINE) \
		-drive file=$(rootfs),format=raw \
		$(QEMU_NETWORK_DEFAULT) $(QEMU_NETWORK_DEVICE)

# Remote access targets
connect_remote: sshkey_check
	ssh -i $(sshkey) -p $(QEMU_SSH_PORT) $(SSH_FLAGS) root@127.0.0.1

copy_to_target: sshkey_check src_dst_check
	scp -i $(sshkey) -P $(QEMU_SSH_PORT) $(SSH_FLAGS) $(src) root@127.0.0.1:$(dst)

copy_from_target: sshkey_check src_dst_check
	scp -i $(sshkey) -P $(QEMU_SSH_PORT) $(SSH_FLAGS) root@127.0.0.1:$(src) $(dst)