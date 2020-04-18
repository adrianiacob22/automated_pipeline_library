FROM jenkins/jenkins:lts-jdk11
LABEL maintainer="adrian.iacob@ro.ibm.com"
ENV refpath /usr/share/jenkins/ref/
ENV groovypath /usr/share/jenkins/ref/init.groovy.d/
ENV pluginpath /usr/share/jenkins/ref/plugins/
ENV uid 1001

USER root
RUN apt-get update && apt-get install -y apt-utils ruby make
#Adding the following configuration to grant permissions for jenkins on the docker mounted socket for communication
RUN mkdir -p ${groovypath}  && \
    mkdir -p ${pluginpath}  && \
    usermod -u ${uid} jenkins  && \
    groupmod -g ${uid} jenkins  && \
    groupadd -g 978 docker && \
    usermod -a -G root jenkins && \
    usermod -a -G docker jenkins && \
    echo "jenkins  ALL=(ALL)       ALL" >> /etc/sudoers && \
    chown -R jenkins:jenkins /usr/share/jenkins/

## Add groovy scripts in files directory
COPY files/*.groovy ${groovypath}

## Abort automatic plugin installation for now
# COPY files/plugins.txt ${refpath}
# RUN  /usr/local/bin/install-plugins.sh < ${refpath}/plugins.txt

# drop back to the regular jenkins user - good practice
USER jenkins

ENV JAVA_OPTS="-Dcom.sun.akuma.Daemon=daemonized -Djava.awt.headless=true -DJENKINS_EMAIL=jenkins@cmsvjenkins21 -Xms1024m -Xmx4096m -Dhudson.model.ParametersAction.keepUndefinedParameters=true -Dhudson.model.DirectoryBrowserSupport.CSP= -Dhudson.tasks.MailSender.SEND_TO_UNKNOWN_USERS=true -Dhudson.tasks.MailSender.SEND_TO_USERS_WITHOUT_READ=true -Dhudson.remoting.ClassFilter=org.jfrog.build.api.Artifact,org.jfrog.build.api.BaseBuildFileBean,org.jfrog.build.api.BaseBuildBean -Dpermissive-script-security.enabled=true -XX:+UseG1GC -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -DJENKINS_HOME=/var/jenkins_home"
ENV JENKINS_OPTS="--logfile=/var/log/jenkins/jenkins.log --webroot=/var/jenkins_home/war --daemon --httpPort=8080 --debug=5 --handlerCountMax=100 --handlerCountMaxIdle=20 --sessionTimeout=1440"
