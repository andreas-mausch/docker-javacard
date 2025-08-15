# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv

# Above is needed to avoid warnings like:
# `SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "GP_KEY") (line 47)`
# Yes, we do set a key here, but explictly to an empty value, which is not recognized by the rule.

# Debian 11 (debian:bookworm-slim) and 12 (debian:bullseye-slim) don't have support for JDK 8
# Latest gp.jar requires Java 11
FROM eclipse-temurin:11.0.27_6-jdk

RUN apt-get update && \
  apt-get install -y \
    ant \
    pcscd \
    pcsc-tools \
    libnfc-bin \
    libpcsclite1 \
    libpcsclite-dev \
    opensc \
    ca-certificates \
    gpshell \
    curl \
    git \
    unzip \
    bash && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# This image is based on Ubuntu and Gradle in Ubuntu is outdated,
# so install it in a specific version.
RUN curl -fsSL https://services.gradle.org/distributions/gradle-8.14.3-bin.zip -o /tmp/gradle-bin.zip && \
  mkdir /opt/gradle && \
  unzip -d /opt/gradle/ /tmp/gradle-bin.zip && \
  mv /opt/gradle/gradle-*.*.*/* /opt/gradle/ && \
  rmdir /opt/gradle/gradle-*.*.*/ && \
  rm /tmp/gradle-bin.zip

ENV JAVA_HOME=/opt/java/openjdk
ENV GRADLE_HOME=/opt/gradle
ENV PATH=$JAVA_HOME/bin:$GRADLE_HOME/bin:$PATH

# Environment variables for GlobalPlatformPro
# https://github.com/martinpaljak/GlobalPlatformPro/wiki/Getting-started

# ENV GP_READER="ACS ACR122U PICC Interface"
# ENV GP_READER_IGNORE="Yubikey;Alcor"
# ENV GP_TRACE=true
# ENV GP_AID

ENV GP_KEY=""
ENV GP_KEY_ENC=""
ENV GP_KEY_MAC=""
ENV GP_KEY_DEK=""

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY ./external /javacard
RUN echo 'alias gp="java -jar /javacard/gp-v24.10.15.jar"' >> ~/.bashrc

WORKDIR /applet

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]
