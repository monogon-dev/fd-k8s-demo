FROM rockylinux@sha256:72afc2e1a20c9ddf56a81c51148ebcbe927c0a879849efe813bee77d69df1dd8

RUN INSTALL_PKGS="git hostname patch bzip2 iproute sudo strace" && \
    dnf install -y --setopt=tsflags=nodocs https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf install -y --setopt=tsflags=nodocs $INSTALL_PKGS

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.73.0

ENV PATH="/root/.cargo/bin:${PATH}"

RUN git clone \
      -b ms1.4 \
      --recurse-submodules \
      --depth=1 \
      --shallow-submodules \
      https://github.com/firedancer-io/firedancer.git

WORKDIR /firedancer

RUN FD_AUTO_INSTALL_PACKAGES=1 ./deps.sh check fetch install

RUN MACHINE=linux_gcc_x86_64 make RUST_PROFILE=release -j fdctl fddev

ENV PATH="/firedancer/build/linux/gcc/x86_64/bin:${PATH}"

RUN useradd firedancer
