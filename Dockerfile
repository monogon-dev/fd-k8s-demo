ARG IMAGE=rockylinux@sha256:72afc2e1a20c9ddf56a81c51148ebcbe927c0a879849efe813bee77d69df1dd8
FROM $IMAGE

RUN INSTALL_PKGS="git hostname patch bzip2 iproute sudo strace systemd-devel xdp-tools jq" && \
    dnf install -y --setopt=tsflags=nodocs https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf install -y --setopt=tsflags=nodocs $INSTALL_PKGS

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.73.0

ENV PATH="/root/.cargo/bin:${PATH}"

RUN git clone \
      -b main \
      --recurse-submodules \
      --depth=1 \
      --shallow-submodules \
      https://github.com/firedancer-io/firedancer.git

WORKDIR /firedancer

# Work around https://github.com/firedancer-io/firedancer/issues/2573
# until https://review.monogon.dev/c/monogon/+/3295 is deployed.
COPY gh-issue-2573.patch .
RUN patch -p1 < gh-issue-2573.patch

RUN FD_AUTO_INSTALL_PACKAGES=1 ./deps.sh check fetch install

RUN MACHINE=linux_gcc_x86_64 make RUST_PROFILE=release -j fdctl fddev --output-sync=target
RUN MACHINE=linux_gcc_x86_64 make RUST_PROFILE=release -j solana --output-sync=target

# Build solana-keygen from unmodified repo
RUN git clone -b v1.18.17 --depth=1 https://github.com/anza-xyz/agave solana-upstream && \
    cd solana-upstream && \
    cargo build --release --bin solana-keygen && \
    cp target/release/solana-keygen /firedancer/build/linux/gcc/x86_64/bin && \
    rm -rf /firedancer/solana-upstream

ENV PATH="/firedancer/build/linux/gcc/x86_64/bin:${PATH}"

COPY bin /usr/local/bin

RUN useradd firedancer
