FROM jenkins/jenkins:lts

# ENV CASC_JENKINS_CONFIG /var/jenkins_home/casc.yaml
# COPY cfg/casc.yaml /var/jenkins_home/casc.yaml

# ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

COPY cfg/plugins.txt /usr/share/jenkins/ref/plugins.txt

RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

EXPOSE 8080

