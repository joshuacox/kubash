# Reactionetes Makefile
# Install location
$(eval KUBASH_DIR := $(HOME)/.kubash)
$(eval KUBASH_BIN := $(KUBASH_DIR)/bin)

# Helm settings
$(eval HELM_INSTALL_DIR := "$(KUBASH_BIN)")

reqs: linuxreqs

linuxreqs: $(KUBASH_BIN) kubectl helm

helm: $(KUBASH_BIN)
	@scripts/kubashnstaller helm

$(KUBASH_BIN)/helm: SHELL:=/bin/bash
$(KUBASH_BIN)/helm:
	@echo 'Installing helm'
	$(eval TMP := $(shell mktemp -d --suffix=HELMTMP))
	curl -Lo $(TMP)/helmget --silent https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get
	HELM_INSTALL_DIR=$(HELM_INSTALL_DIR) \
	sudo -E bash -l $(TMP)/helmget
	rm $(TMP)/helmget
	rmdir $(TMP)

kubectl: $(KUBASH_BIN)
	@scripts/kubashnstaller kubectl

$(KUBASH_BIN)/kubectl:
	@echo 'Installing kubectl'
	$(eval TMP := $(shell mktemp -d --suffix=KUBECTLTMP))
	cd $(TMP) \
	&& curl -LO https://storage.googleapis.com/kubernetes-release/release/$(MY_KUBE_VERSION)/bin/linux/amd64/kubectl \
	&& chmod +x kubectl \
	&& sudo mv -v kubectl $(KUBASH_BIN)/
	rmdir $(TMP)

$(KUBASH_BIN):
	mkdir -p $(KUBASH_BIN)

vanity:
	curl -i https://git.io -F "url=https://raw.githubusercontent.com/joshuacox/kubash/master/bootstrap" -F "code=kubash"

crictl: $(KUBASH_BIN)
	@scripts/kubashnstaller crictl

$(KUBASH_BIN)/crictl: SHELL:=/bin/bash
$(KUBASH_BIN)/crictl:
	@echo 'Installing cri-tools'
	$(eval TMP := $(shell mktemp -d --suffix=CRITMP))
	cd $(TMP) \
	  && git clone --depth=1 https://github.com/kubernetes-incubator/cri-tools.git
	cd $(TMP)/cri-tools \
	  && make && sudo make install
	rmdir $(TMP)

packer: $(KUBASH_BIN)
	@scripts/kubashnstaller packer

$(KUBASH_BIN)/packer: SHELL:=/bin/bash
$(KUBASH_BIN)/packer:
	@echo 'Installing packer'
	$(eval PACKER_VERSION:=1.1.3)
	$(eval TMP := $(shell mktemp -d --suffix=GOTMP))
	cd $(TMP) \
	&& wget -c \
	https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip
	cd $(TMP) \
	&& unzip packer_$(PACKER_VERSION)_linux_amd64.zip
	rm $(TMP)/packer_$(PACKER_VERSION)_linux_amd64.zip
	mv $(TMP)/packer $(KUBASH_BIN)/packer 
	rmdir $(TMP)

go-build-docker:
	@echo 'Installing packer'
	$(eval TMP := $(shell mktemp -d --suffix=GOTMP))
	cd $(TMP) \
	go get github.com/hashicorp/packer
	rmdir $(TMP)

example:
	cp -iv hosts.csv.example hosts.csv
	cp -iv provision.list.example provision.list

pax/ubuntu/builds/ubuntu-16.04.libvirt.box:
	TMPDIR=/tiamat/tmp packer build -only=qemu kubash-ubuntu-16.04-amd64.json

bats: $(KUBASH_BIN)
	@scripts/kubashnstaller bats

$(KUBASH_BIN)/bats:
	$(eval TMP := $(shell mktemp -d --suffix=BATSTMP))
	cd $(TMP) \
	&& git clone --depth=1 https://github.com/sstephenson/bats.git
	ls -lh $(TMP)
	ls -lh $(TMP)/bats
	cd $(TMP)/bats \
	&& sudo ./install.sh /usr/local
	rm -Rf $(TMP)
