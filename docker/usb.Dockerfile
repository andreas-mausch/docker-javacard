# Debian 11 (debian:bookworm-slim) and 12 (debian:bullseye-slim) don't have support for JDK 8
FROM eclipse-temurin:11-jdk

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
    curl \
    git \
    unzip \
    bash && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH
# ENV GP_READER="ACS ACR122U PICC Interface"
# ENV GP_READER_IGNORE="Yubikey;Alcor"
# ENV GP_TRACE=true
# ENV GP_AID

COPY ./external /javacard
RUN echo 'alias gp="java -jar /javacard/gp-v24.10.15.jar"' >> ~/.bashrc

# You might need to `pcscd --disable-polkit`:
# https://github.com/LudovicRousseau/PCSC/issues/59
CMD ["bash", "-c", "service pcscd start && bash"]
