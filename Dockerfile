# s2i-springboot : 12-08-2017
#
# springboot-java
#
FROM openshift/base-centos7
MAINTAINER Ganesh Radhakrishnan ganrad01@gmail.com
# HOME in base image is /opt/app-root/src

# Builder version
ENV BUILDER_VERSION 1.0

LABEL io.k8s.description="Platform for building Spring Boot applications with maven or gradle" \
      io.k8s.display-name="Spring Boot builder 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="Java,Springboot,builder"

# Install required util packages.
RUN yum -y update; \
    yum install tar -y; \
    yum install unzip -y; \
    yum install ca-certificates -y; \
    yum install sudo -y; \
    yum clean all -y

# Install OpenJDK 1.8, create required directories.
RUN yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    yum clean all -y && \
    mkdir -p /opt/openshift

# Install Maven 3.5.2
#ARG MAVEN_VER=3.6.3
#ENV MAVEN_VERSION MAVEN_VER
RUN (curl -fSL https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    mv /usr/local/apache-maven-3.6.3 /usr/local/maven && \
    ln -sf /usr/local/maven/bin/mvn /usr/local/bin/mvn && \
    mkdir -p $HOME/.m2 && chmod -R a+rwX $HOME/.m2

# Install Gradle 4.4
ARG GRADLE_VER=6.5.1
ENV GRADLE_VERSION GRADLE_VER
RUN curl -fSL https://services.gradle.org/distributions/gradle-6.5.1-bin.zip -o /tmp/gradle-6.5.1-bin.zip && \
    unzip /tmp/gradle-6.5.1-bin.zip -d /usr/local/ && \
    rm /tmp/gradle-6.5.1-bin.zip && \
    mv /usr/local/gradle-6.5.1 /usr/local/gradle && \
    ln -sf /usr/local/gradle/bin/gradle /usr/local/bin/gradle && \
    mkdir -p $HOME/.gradle && chmod -R a+rwX $HOME/.gradle

# Set the location of the mvn and gradle bin directories on search path
ENV PATH=/usr/local/bin/mvn:/usr/local/bin/gradle:$PATH

# Set the default build type to 'Maven'
ENV BUILD_TYPE=Maven

# Drop the root user and make the content of /opt/openshift owned by user 1001
RUN chown -R 1001:1001 /opt/openshift /opt/app-root/src

# Change perms on target/deploy directory to 777
RUN chmod -R 777 /opt/openshift /opt/app-root/src

# Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way.
COPY ./s2i/bin/ /usr/libexec/s2i
RUN chmod -R 777 /usr/libexec/s2i

# This default user is created in the openshift/base-centos7 image
USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

# Set the default CMD for the image
CMD ["/usr/libexec/s2i/usage"]
