# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv

# Above is needed to avoid warnings like:
# `SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "GP_KEY") (line 47)`
# Yes, we do set a key here, but explictly to an empty value, which is not recognized by the rule.

# Debian 11 (debian:bookworm-slim) and 12 (debian:bullseye-slim) don't have support for JDK 8
# Latest gp.jar requires Java 11
FROM eclipse-temurin:11.0.27_6-jdk

# I cannot include the JavaCard DevKit Simulator in this repo,
# that is why this is disabled by default.
# If you want to enable it, download the simulator and build the
# docker image with the flag enabled.
ARG JAVACARD_SIMULATOR
# ARG JAVACARD_SIMULATOR="java_card_devkit_simulator-linux-bin-v25.0-b_474-23-APR-2025.tar.gz"

RUN apt-get update && \
  apt-get install -y \
    ant \
    pcscd \
    pcsc-tools \
    libnfc-bin \
    libnfc-examples \
    libpcsclite1 \
    libpcsclite-dev \
    opensc \
    ca-certificates \
    gpshell \
    python3-pip \
    python3-pykcs11 \
    python3-pyscard \
    python3-virtualsmartcard \
    vsmartcard-vpcd \
    curl \
    git \
    unzip \
    bash \
    # gcc-multilib is required to run 32-bit executables like the
    # Oracle JavaCard Simulator jcsl
    gcc-multilib && \
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

# Install pcsc_ndef
RUN mkdir /opt/pcsc-ndef && \
  git clone https://github.com/Giraut/pcsc-ndef /opt/pcsc-ndef && \
  git -C /opt/pcsc-ndef checkout b4acbf975e387fca77644fdf4767c531a54f94e5 && \
  install -m 755 /opt/pcsc-ndef/pcsc_ndef.py /usr/bin/pcsc_ndef

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

# JavaCard simulator
RUN if [ -n "$JAVACARD_SIMULATOR" ] ; then \
  cp /javacard/oracle_javacard_simulator/jcsdk_config /etc/reader.conf.d/ \
  && mkdir -p /opt/javacard/simulator/ \
  && tar -xzf "/javacard/oracle_javacard_simulator/$JAVACARD_SIMULATOR" -C /opt/javacard/simulator/ \
  && java -jar /opt/javacard/simulator/tools/Configurator.jar \
    -binary /opt/javacard/simulator/runtime/bin/jcsl \
    -SCP-keyset \
      10 `# KVN (Key Version Number)` \
      1111111111111111111111111111111111111111111111111111111111111111 `# ENC` \
      2222222222222222222222222222222222222222222222222222222222222222 `# MAC` \
      3333333333333333333333333333333333333333333333333333333333333333 `# DEK` \
    -global-pin 01020304050f 03 \
  ; fi

WORKDIR /applet

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]
