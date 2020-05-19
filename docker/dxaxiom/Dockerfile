#This Dockerfile creates an image with specific version of Affymetrix Power Tools (APT)
# The APT version is specified at build time using --build-arg APT_VERSION=...
# There is no entrypoint defined.
FROM debian:buster-slim

LABEL com.dnanex.tool="dxaxiom"

RUN apt update \
 && apt -y install python3.7 python3-pip wkhtmltopdf\
 && pip3 install --upgrade pip \
 && pip3 install jinja2 pandas pdfkit matplotlib

