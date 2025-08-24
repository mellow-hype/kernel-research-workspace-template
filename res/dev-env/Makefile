BULLSEYE_TAG := bullseye-dev
SID_TAG := sid-dev
BOOKWORM_TAG := bookworm-dev

init: init_bullseye init_sid init_bookworm
	$(info All done!)

check_docker_installed:
	if ! [ -x "$$(command -v docker)" ]; then echo "Error: docker is not installed." >&2; exit 1; fi

init_bullseye: check_docker_installed
	$(info Creating 'bullseye-dev' image)
	sudo docker build -t $(BULLSEYE_TAG) -f bullseye-dev.Dockerfile .

init_sid: check_docker_installed
	$(info Creating 'sid-dev' image)
	sudo docker build -t $(SID_TAG) -f sid-dev.Dockerfile .

init_bookworm: check_docker_installed
	$(info Creating 'bookworm-dev' image)
	sudo docker build -t $(BOOKWORM_TAG) -f bookworm-dev.Dockerfile .

check_mnt:
ifndef mnt
	$(error mnt is not set. Usage: 'make mnt=path/to/mountpoint $@')
	exit 1
endif
	if [ ! -d $(mnt) ]; then echo "Directory $(mnt) does not exist"; exit 1; fi

run_bullseye: check_mnt
	$(info Starting 'bullseye-dev' container)
	sudo docker run -v $(mnt)/:/home/$(BULLSEYE_TAG)/src --rm -it $(BULLSEYE_TAG)

run_sid: check_mnt
	$(info Starting 'sid-dev' container)
	sudo docker run -v $(mnt)/:/home/$(SID_TAG)/src --rm -it $(SID_TAG)

run_bookworm: check_mnt
	$(info Starting 'bookworm-dev' container)
	sudo docker run -v $(mnt)/:/home/$(BOOKWORM_TAG)/src --rm -it $(BOOKWORM_TAG)