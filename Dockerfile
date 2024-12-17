FROM 243488295326.dkr.ecr.ap-southeast-2.amazonaws.com/md_dataset_package_base:0.3.8-105
# FROM md_dataset_base-linux:latest

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

RUN pip install git+https://github.com/MassDynamics/md_dataset.git@${PACKAGE_VERSION}

RUN pip install -e .
