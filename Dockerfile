FROM ubuntu:22.04

# This the release tag of virtual-environments: https://github.com/actions/virtual-environments/releases
ARG UBUNTU_VERSION=2204
ARG VIRTUAL_ENVIRONMENT_VERSION=ubuntu20/20240401.4

ENV UBUNTU_VERSION=${UBUNTU_VERSION} VIRTUAL_ENVIRONMENT_VERSION=${VIRTUAL_ENVIRONMENT_VERSION}
#ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Europe/Vienna
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install base packages.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    sudo \
    lsb-release \
    software-properties-common \
    gnupg-agent \
    openssh-client \
    make \
    rsync \
    wget \
    jq \
    curl \
    libnss3 libnss3-dev \
    zip unzip \
    amazon-ecr-credential-helper && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add sudo rule for runner user
RUN echo "runner ALL= EXEC: NOPASSWD:ALL" >> /etc/sudoers.d/runner

# Update git.
RUN add-apt-repository -y ppa:git-core/ppa && \
    apt-get update && \
    apt-get -y install --no-install-recommends git=1:2.42.* && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install docker cli.
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg > /etc/apt/trusted.gpg.d/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli=5:20.10.* && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy scripts.
COPY scripts/ /usr/local/bin/

# Install additional distro packages and runner virtual envs
ARG VIRTUAL_ENV_PACKAGES=""
ARG VIRTUAL_ENV_INSTALLS="basic java-tools python aws azure-cli github-cli docker-compose nodejs sbt kotlin"
RUN apt-get -y update && \
    ( [ -z "$VIRTUAL_ENV_PACKAGES" ] || apt-get -y --no-install-recommends install $VIRTUAL_ENV_PACKAGES ) && \
    . /usr/local/bin/install-from-virtual-env-helpers && \
    for package in ${VIRTUAL_ENV_INSTALLS}; do \
        install-from-virtual-env $package;  \
    done && \
    apt-get -y install --no-install-recommends gosu && \
    apt-get -y clean && \
    rm -rf /virtual-environments /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# configure JAVA environment variables
ENV JAVA_HOME_8_X64=/usr/lib/jvm/temurin-8-jdk-amd64/
ENV JAVA_HOME_11_X64=/usr/lib/jvm/temurin-11-jdk-amd64/
ENV JAVA_HOME_17_X64=/usr/lib/jvm/temurin-17-jdk-amd64/

# Install runner and its dependencies.
RUN groupadd -g 121 runner && useradd -mr -d /home/runner -u 1001 -g 121 runner && \
    install-runner

COPY entrypoint.sh /
WORKDIR /home/runner
USER runner
ENTRYPOINT ["/entrypoint.sh"]
