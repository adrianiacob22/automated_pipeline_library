FROM jenkinsci/jnlp-slave
ENV JENKINS_HOST 192.168.100.3
ENV JENKINS_PORT 443
USER root
COPY cert.cer /tmp/cert.cer
RUN /bin/bash -xv -c 'keytool -noprompt -importcert -alias local-CA \
  -keystore $(find /usr -path '*/lib/security/cacerts') \
  -storepass changeit \
  -file /tmp/cert.cer'
USER jenkins
