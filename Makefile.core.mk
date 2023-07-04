SHELL := /bin/bash -o pipefail

export BASE_VERSION ?= 2022-10-27T19-02-22

export HUB ?= higress-registry.cn-hangzhou.cr.aliyuncs.com/higress

export CHARTS ?= higress-registry.cn-hangzhou.cr.aliyuncs.com/charts

VERSION_PACKAGE := github.com/alibaba/higress/pkg/cmd/version

GIT_COMMIT:=$(shell git rev-parse HEAD)

GO_LDFLAGS += -X $(VERSION_PACKAGE).higressVersion=$(shell cat VERSION) \
	-X $(VERSION_PACKAGE).gitCommitID=$(GIT_COMMIT)

GO ?= go

export GOPROXY ?= https://proxy.golang.com.cn,direct

GOARCH_LOCAL := $(TARGET_ARCH)
GOOS_LOCAL := $(TARGET_OS)
RELEASE_LDFLAGS='$(GO_LDFLAGS) -extldflags -static -s -w'

export OUT:=$(TARGET_OUT)
export OUT_LINUX:=$(TARGET_OUT_LINUX)

# If tag not explicitly set in users' .istiorc.mk or command line, default to the git sha.
TAG ?= $(shell git rev-parse --verify HEAD)
ifeq ($(TAG),)
  $(error "TAG cannot be empty")
endif

VARIANT :=
ifeq ($(VARIANT),)
  TAG_VARIANT:=${TAG}
else
  TAG_VARIANT:=${TAG}-${VARIANT}
endif

HIGRESS_DOCKER_BUILD_TOP:=${OUT_LINUX}/docker_build

HIGRESS_BINARIES:=./cmd/higress

HGCTL_BINARIES:=./apiserver/cmd/server

$(OUT):
	@mkdir -p $@

.PHONY: build-hgctl-multiarch
build-hgctl-multiarch: $(OUT)
	GOPROXY=$(GOPROXY) GOOS=linux GOARCH=amd64 LDFLAGS=$(RELEASE_LDFLAGS) tools/gobuild.sh ./out/linux_amd64/ $(HGCTL_BINARIES)
	GOPROXY=$(GOPROXY) GOOS=linux GOARCH=arm64 LDFLAGS=$(RELEASE_LDFLAGS) tools/gobuild.sh ./out/linux_arm64/ $(HGCTL_BINARIES)
	GOPROXY=$(GOPROXY) GOOS=darwin GOARCH=amd64 LDFLAGS=$(RELEASE_LDFLAGS) tools/gobuild.sh ./out/darwin_amd64/ $(HGCTL_BINARIES)
	GOPROXY=$(GOPROXY) GOOS=darwin GOARCH=arm64 LDFLAGS=$(RELEASE_LDFLAGS) tools/gobuild.sh ./out/darwin_arm64/ $(HGCTL_BINARIES)
