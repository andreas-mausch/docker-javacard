# Debian 11 (debian:bookworm-slim) and 12 (debian:bullseye-slim) don't have support for JDK 8
FROM eclipse-temurin:11.0.27_6-jdk

# Latest gp.jar requires Java 11

RUN apt-get update && \
  apt-get install -y \
    ant \
    gradle \
    pcscd \
    pcsc-tools \
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

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

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
