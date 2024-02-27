PROJECT_ID = project-Gg9k0x808vJXGpZV4x07q3Y7
TAG = dnanexus/apt:2.11.8
TARBALL = $(shell echo $(TAG) | sed "s/[:/]/-/g").tar.gz

img:
    docker build --tag=$(TAG) --platform linux/amd64 .

shell:
    docker run --rm -it $(TAG) bash

tarball:
    docker save $(TAG) | gzip > $(TARBALL)

upload: tarball
    dx upload $(TARBALL) -p --path $(PROJECT_ID):/docker/