ARG BASE_TAG=latest
ARG BASE_IMAGE=massdynamics/md_dataset_package_r_base:${BASE_TAG}
FROM ${BASE_IMAGE}

RUN yum -y update
RUN yum install harfbuzz-devel fribidi-devel libpng-devel
RUN dnf install -y libtiff-devel
RUN yum install freetype-devel libjpeg-devel pkg-config

RUN yum install -y gcc gcc-c++ make automake autoconf libtool
RUN yum install libcurl-devel libxml2-devel openssl-devel

COPY ./dependencies.R .
RUN Rscript dependencies.R

COPY DESCRIPTION ./install.R .
COPY NAMESPACE LICENSE README.md .
COPY src/ ./src/
COPY R/ ./R/

RUN Rscript install.R

COPY pyproject.toml .
RUN pip install -e .
