FROM 243488295326.dkr.ecr.ap-southeast-2.amazonaws.com/md_dataset_package:0.3.4-59
# FROM md_dataset_package-linux:latest

RUN yum -y update
RUN yum install harfbuzz-devel fribidi-devel libpng-devel
RUN yum install build-essential libcurl4-gnutls-dev libxml2-dev libssl-dev

ADD process.R .
ADD process_r.py .

ADD ./dependencies.R .
RUN Rscript dependencies.R

ADD ./install.R .
RUN Rscript install.R
