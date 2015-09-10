#Merged in base jdk1.7-rhel7.0 into single image, until base-images can be refereneced from local OSEv3 repo
FROM rhel7.0
MAINTAINER Greg Hoelzer ghoelzer@redhat.com

# Install packages necessary to run Java Apps
RUN yum --disablerepo rhel-sap-hana-for-rhel-7-server-rpms -y install git saxon unzip java-1.7.0-openjdk-devel.x86_64 && yum clean all

# Set JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/jre-1.7.0

RUN yum update -y && yum install -y wget git curl zip && yum clean all && rm -rf /var/lib/apt/lists/*

ENV JENKINS_HOME /var/jenkins_home

# Jenkins is ran with user `jenkins`, uid = 1000
# If you bind mount a volume from host/vloume from a data container, 
# ensure you use same uid
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins

# Jenkins home directoy is a volume, so configuration and build history 
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d


ADD ./init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

ENV JENKINS_VERSION 1.609.1
ENV JENKINS_SHA 698284ad950bd663c783e99bc8045ca1c9f92159

# could use ADD but this one does not check Last-Modified header 
# see https://github.com/docker/docker/issues/8331
RUN curl -fL http://mirrors.jenkins-ci.org/war-stable/$JENKINS_VERSION/jenkins.war -o /usr/share/jenkins/jenkins.war \
  && echo "$JENKINS_SHA /usr/share/jenkins/jenkins.war" | sha1sum -c -

ENV JENKINS_UC https://updates.jenkins-ci.org
RUN chown -R jenkins "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

ENV COPY_REFERENCE_FILE_LOG /var/log/copy_reference_file.log
RUN touch $COPY_REFERENCE_FILE_LOG && chown jenkins.jenkins $COPY_REFERENCE_FILE_LOG

USER jenkins

ADD ./jenkins.sh /usr/local/bin/jenkins.sh
CMD ["/bin/bash", "/usr/local/bin/jenkins.sh"]
#ENTRYPOINT ["/usr/local/bin/jenkins.sh"]

# from a derived Dockerfile, can use `RUN plugin.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
ADD ./plugins.sh /usr/local/bin/plugins.sh
