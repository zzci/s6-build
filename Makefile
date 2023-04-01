#!/usr/bin/make -f

NAME = s6-build
BUILDDIR ?= $(CURDIR)/build
DOCKER := $(shell which docker)

all: build

build:
	mkdir -p $(BUILDDIR)
	$(DOCKER) buildx create --name $(NAME)-builder || true
	$(DOCKER) buildx use $(NAME)-builder
	$(DOCKER) buildx build \
		--platform linux/amd64 \
		-t  $(NAME)-dev-amd64 --rm \
		--load \
		-f Dockerfile .
	$(DOCKER) rm -f $(NAME)-temp-amd64 || true
	$(DOCKER) create -ti --name $(NAME)-temp-amd64 $(NAME)-dev-amd64
	$(DOCKER) cp -a $(NAME)-temp-amd64:/command/bin/ $(BUILDDIR)/
	$(DOCKER) rm -f $(NAME)-temp-amd64
	$(DOCKER) buildx rm $(NAME)-builder

clean:
	rm -rf $(BUILDDIR)/

.PHONY: build clean