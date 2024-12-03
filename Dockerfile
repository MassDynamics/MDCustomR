FROM 243488295326.dkr.ecr.ap-southeast-2.amazonaws.com/md_dataset_package:0.3.4-59
# FROM md_dataset_package-linux:latest

RUN yum -y update

ADD process.R .
ADD process_r.py .
