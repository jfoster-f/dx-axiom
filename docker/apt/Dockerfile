#This Dockerfile creates an image with specific version of Affymetrix Power Tools (APT)
# The APT version is specified at build time using --build-arg APT_VERSION=...
# There is no entrypoint defined.
FROM debian:stretch-slim

LABEL com.dnanex.tool="apt"

ARG APT_VERSION

ADD https://downloads.thermofisher.com/APT/APT${APT_VERSION}/apt_${APT_VERSION}_linux_64_bit_x86_binaries.zip /tmp/apps/apt.zip

RUN apt update \
 && apt -y install zip unzip \
 && cd /tmp/apps \
 && mkdir apt \
 && unzip apt.zip -d apt \
 && chmod +x apt/apt_${APT_VERSION}_linux_64_bitx86_binaries/bin/* \
 && mv apt/apt_${APT_VERSION}_linux_64_bitx86_binaries/bin/* /usr/local/bin \
 && cd / \
 && rm -Rf /tmp/appsdoc

