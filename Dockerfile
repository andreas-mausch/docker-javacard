# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv

# Above is needed to avoid warnings like:
# `SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ENV "GP_KEY") (line 47)`
# Yes, we do set a key here, but explictly to an empty value, which is not recognized by the rule.

FROM debian:trixie-20261104-slim

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
    python3-pip \
    python3-pykcs11 \
    python3-pyscard \
    python3-virtualsmartcard \
    vsmartcard-vpcd \
    curl \
    git \
    unzip \
    bash \
    wget \
    gpg \
    apt-transport-https \
    # gcc-multilib is required to run 32-bit executables like the
    # Oracle JavaCard Simulator jcsl
    gcc-multilib \
    # gnutls-bin contains p11tool
    gnutls-bin \
    pkcs11-provider \
    libengine-pkcs11-openssl \
    yubico-piv-tool \
    yubikey-manager \
    oathtool \
    pipx \
    usbutils \
    fido2-tools && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Install gpShell 3 from upstream:
# Debian only ships 2.4.0 (from 2023), upstream provides 3.0.0 as a "static"
# DEB that contains both the legacy gpshell script interpreter and the new
# task-oriented gpshell3 CLI. It links against libpcsclite (installed above).
RUN curl -fsSL https://github.com/kaoh/globalplatform/releases/download/3.0.0/gpshell-3.0.0-static.deb -o /tmp/gpshell.deb && \
  echo "ec1301a27b2a51f88d71e22c5e404e63569a4edfbce1e7f767dccfc458181400 /tmp/gpshell.deb" | sha256sum --check && \
  dpkg -i /tmp/gpshell.deb && \
  rm /tmp/gpshell.deb

# FIDO2: USB-HID to PC/SC bridge
RUN pipx install git+https://github.com/BryanJacobs/fido2-hid-bridge

# Add the adoptium / temurin apt repository
# Debian 11 (debian:bookworm-slim) and 12 (debian:bullseye-slim) don't have support for JDK 8
# Latest gp.jar requires Java 11
RUN wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /etc/apt/trusted.gpg.d/adoptium.gpg > /dev/null \
  && echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

RUN apt-get update && \
  apt-get install -y \
    temurin-25-jdk \
    temurin-11-jdk \
    temurin-8-jdk \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && update-java-alternatives --set temurin-25-jdk-amd64 \
  && update-java-alternatives --list

# This image is based on Ubuntu and Gradle in Ubuntu is outdated,
# so install Gradle in a specific version.
RUN curl -fsSL https://services.gradle.org/distributions/gradle-8.14.3-bin.zip -o /tmp/gradle-bin.zip && \
  echo "bd71102213493060956ec229d946beee57158dbd89d0e62b91bca0fa2c5f3531 /tmp/gradle-bin.zip" | sha256sum --check && \
  mkdir /opt/gradle && \
  unzip -d /opt/gradle/ /tmp/gradle-bin.zip && \
  mv /opt/gradle/gradle-*.*.*/* /opt/gradle/ && \
  rmdir /opt/gradle/gradle-*.*.*/ && \
  rm /tmp/gradle-bin.zip

# Debian ships an outdated Maven (3.9.9), but the javacard-parent enforcer
# requires >= 3.9.16, so install Maven in a specific version like Gradle.
# archive.apache.org keeps old releases, so the pinned URL stays valid.
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.9.16/binaries/apache-maven-3.9.16-bin.tar.gz -o /tmp/maven-bin.tar.gz && \
  echo "831a8591fe20c8243b1dbe7d71e3244f31d1665b0804b2e825e38cbbe5ce0cafb8338851f90780735568773e0a6cd07bbec107cda0b896b008b861075358b6f6 /tmp/maven-bin.tar.gz" | sha512sum --check && \
  mkdir /opt/maven && \
  tar -xzf /tmp/maven-bin.tar.gz -C /opt/maven --strip-components=1 && \
  rm /tmp/maven-bin.tar.gz

# Install pcsc_ndef
RUN mkdir /opt/pcsc-ndef && \
  git clone https://github.com/Giraut/pcsc-ndef /opt/pcsc-ndef && \
  git -C /opt/pcsc-ndef checkout b4acbf975e387fca77644fdf4767c531a54f94e5 && \
  install -m 755 /opt/pcsc-ndef/pcsc_ndef.py /usr/bin/pcsc_ndef

ENV JAVA_HOME=/usr/lib/jvm/temurin-25-jdk-amd64
ENV GRADLE_HOME=/opt/gradle
ENV MAVEN_HOME=/opt/maven
ENV MAVEN_OPTS="-Djavacard.sdk.path=/javacard/oracle_javacard_sdks/jc305u4_kit"
ENV PATH=$GRADLE_HOME/bin:$MAVEN_HOME/bin:/root/.local/bin:$PATH

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
RUN echo 'alias gp="java -jar /javacard/gp-v25.10.20.jar"' >> ~/.bashrc

# I cannot include the JavaCard DevKit Simulator in this repo,
# that is why this is disabled by default.
# If you want to enable it, download the simulator and build the
# docker image with the flag enabled.
ARG JAVACARD_SIMULATOR
# ARG JAVACARD_SIMULATOR="java_card_devkit_simulator-linux-bin-v26.0-b_788-05-MAY-2026.tar.gz"

# JavaCard simulator
RUN if [ -n "$JAVACARD_SIMULATOR" ] ; then \
  cp /javacard/oracle_javacard_simulator/jcsdk_config /etc/reader.conf.d/ \
  && mkdir -p /opt/javacard/simulator/ \
  && tar -xzf "/javacard/oracle_javacard_simulator/$JAVACARD_SIMULATOR" -C /opt/javacard/simulator/ \
  && java -jar /opt/javacard/simulator/tools/Configurator.jar \
    -binary /opt/javacard/simulator/runtime/bin/jcsl \
    -SCP-keyset \
      10 `# KVN (Key Version Number)` \
      404142434445464748494A4B4C4D4E4F `# ENC` \
      404142434445464748494A4B4C4D4E4F `# MAC` \
      404142434445464748494A4B4C4D4E4F `# DEK` \
    -global-pin 01020304050f 03 \
  ; fi

# Enable the OpenSSL legacy provider.
# Reason: SCP02 (gpshell3/gpshell via the static-3.0.0 deb, OpenSSL 3.0.2 core)
# needs single DES (EVP_des_cbc in calculate_MAC_des_3des for the SCP02
# EXTERNAL AUTHENTICATE MAC), and OpenSSL 3.x only provides single DES in the
# legacy provider. Without it, SCP02 mutual authentication fails with
# "error:0308010C:digital envelope routines::unsupported" (0x8030F00C).
# gpshell3 reads /usr/lib/ssl/openssl.cnf (== /etc/ssl/openssl.cnf) and loads
# /usr/lib/x86_64-linux-gnu/ossl-modules/legacy.so. Provider ABI is stable
# across OpenSSL 3.x, so Debian's 3.5.x module works with the 3.0.2 core
# (verified). When activating any provider explicitly, the default provider
# must be activated too, otherwise it becomes unavailable.
RUN sed -i \
    -e '/^\[provider_sect\]/a legacy = legacy_sect' \
    -e 's/^# activate = 1$/activate = 1/' \
    /etc/ssl/openssl.cnf && \
  printf '\n# Enabled for GlobalPlatform SCP02 (single DES), see gpshell docs\n[legacy_sect]\nactivate = 1\n' >> /etc/ssl/openssl.cnf

WORKDIR /applet

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]
