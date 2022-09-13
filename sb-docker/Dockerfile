FROM rockylinux:latest
LABEL maintainer=jerichorivera

RUN dnf update -y \
    && curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | bash \
    && dnf install sysbench mysql -y && \
    yum clean all -y

