FROM 243488295326.dkr.ecr.ap-southeast-2.amazonaws.com/md_dataset_package:0.3.7-83 AS build
# FROM md_dataset_package-linux:latest AS build

RUN yum -y update

ARG PACKAGE_VERSION
ENV WORK_DIR="/usr/src/app"
WORKDIR $WORK_DIR

RUN pip install --no-cache-dir --upgrade pip setuptools wheel build
COPY . .
RUN python -m build && ls -l /usr/src/app/dist/

FROM 243488295326.dkr.ecr.ap-southeast-2.amazonaws.com/md_dataset_package:0.3.7-83
# FROM md_dataset_package-linux:latest

RUN yum -y update

ENV WORK_DIR="/usr/src/app"
WORKDIR $WORK_DIR

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

ARG PACKAGE_VERSION
RUN pip install --no-cache-dir --upgrade pip
COPY --from=build /usr/src/app/dist/md_custom_r-${PACKAGE_VERSION}-py3-none-any.whl /tmp/
RUN pip install --no-cache-dir /tmp/md_custom_r-${PACKAGE_VERSION}-py3-none-any.whl
