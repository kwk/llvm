FROM fedora:33

RUN dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    @development-tools \
    binutils-devel \
    ccache \
    clang \
    cmake \
    compat-openssl10 \
    curl \
    diffutils \
    fedora-packager \
    findutils \
    gcc \
    gcc-c++ \
    gdb \
    git \
    glibc-all-langpacks \
    gnupg2 \
    golang \
    inotify-tools \
    jq \
    krb5-libs \
    libatomic \
    libedit-devel \
    libffi-devel \
    libicu \
    libstdc++-static \
    libxml2-devel \
    lld \
    lttng-ust \
    make \
    mock \
    mock-core-configs \
    mock-filesystem \
    mock-scm \
    multilib-rpm-config  \
    nano \
    ncurses-devel \
    ninja-build \
    openssl-libs \
    patch \
    python3 \
    python3-devel \
    python3-pip \
    python3-psutil \
    python3-recommonmark \
    python3-service-identity \
    python3-sphinx \
    python3-virtualenv \
    redhat-lsb-core \
    rsync \
    swig \
    tar \
    valgrind-devel \
    xz-devel \
    zip \
    zlib \
    zlib-devel \
   && dnf clean all

# TODO(kwk): Remove vim when no longer needed
RUN dnf install -y --setopt=tsflags=nodocs --setopt=install_weak_deps=False \
    vim \
    && dnf clean all

# Install Buildbot from pip
# See http://trac.buildbot.net/wiki/RunningBuildbotWithVirtualEnv
RUN useradd --create-home johndoe
WORKDIR /home/johndoe

# Volumes to mount secrets into the container
VOLUME /secret-volume

COPY home/ /home/johndoe/

LABEL maintainer="Konrad Kleine <kkleine@redhat.com>"

ENTRYPOINT [ "/home/johndoe/bin/uid_entrypoint.sh" ]

CMD [ "/home/johndoe/bin/start.sh" ]

RUN chmod +x /home/johndoe/bin/*
RUN chgrp -R 0 /home/johndoe \
    && chmod -R g=u /home/johndoe /etc/passwd

USER 10001

# This is crucial for some spectool and rpm building things
ENV HOME=/home/johndoe
