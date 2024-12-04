FROM 243488295326.dkr.ecr.ap-southeast-2.amazonaws.com/md_dataset_package:0.3.4-59
# FROM md_dataset_package-linux:latest

RUN yum -y update
RUN yum install harfbuzz-devel fribidi-devel libpng-devel
RUN dnf install -y libtiff-devel
RUN yum install freetype-devel libjpeg-devel pkg-config

RUN yum install -y gcc gcc-c++ make automake autoconf libtool
RUN yum install libcurl-devel libxml2-devel openssl-devel

COPY process.R .
COPY process_r.py .
COPY R/ ./R/
COPY DESCRIPTION .
COPY NAMESPACE .

COPY ./dependencies.R .
RUN Rscript dependencies.R

COPY ./install.R .
RUN Rscript install.R
