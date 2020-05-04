FROM centos:centos7
LABEL maintainer="adrianiacob22@gmail.com"

# Install Essentials
RUN yum update -y && \
    yum clean all

# Install Packages
RUN yum install -y git && \
    yum install -y wget && \
	yum install -y java-11-openjdk-devel && \
	yum install -y sudo && \
	yum clean all

ARG user=jenkins
ARG group=jenkins
ARG uid=1001
ARG gid=1001

ENV JENKINS_HOME /home/${user}

# Jenkins is run with user `jenkins`, uid = 1001
RUN groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    && usermod -g wheel ${user}

RUN chown -R ${user}:${user} /home/${user}

# Add the jenkins user to sudoers
RUN echo "${user}    ALL=(ALL)    ALL" >> etc/sudoers
