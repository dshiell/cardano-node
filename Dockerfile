
FROM ubuntu:20.04 as builder

ARG CABAL_VERSION=3.4.0.0
ARG GHC_VERSION=8.10.2
ARG CARDANO_VERSION=1.26.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    haskell-platform \
    build-essential \
    pkg-config \
    libffi-dev \
    libgmp-dev \
    libssl-dev \
    libtinfo-dev \
    libsystemd-dev \
    zlib1g-dev \
    make \
    g++ \
    git \
    jq \
    libncursesw5 \
    llvm-9 \
    libnuma-dev \
    libtool \
    upx

ENV PATH="/root/.cabal/bin:/root/.local/bin:${PATH}"

WORKDIR /src

# install libsodium
RUN git clone https://github.com/input-output-hk/libsodium && \
    cd libsodium && \
    git checkout 66f017f1 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install

ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}" \
    PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}"

# download cabal
RUN wget http://hackage.haskell.org/package/cabal-install-${CABAL_VERSION}/cabal-install-${CABAL_VERSION}.tar.gz \
    && tar -xf cabal-install-${CABAL_VERSION}.tar.gz \
    && cd cabal-install-${CABAL_VERSION} \
    && cabal update \
    && cabal install \
    && cabal --version

RUN wget -q http://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-aarch64-deb10-linux.tar.xz \
    && tar -xf ghc-${GHC_VERSION}-aarch64-deb10-linux.tar.xz \
    && cd ghc-${GHC_VERSION} \
    && ./configure \
    && make install
    
# fetch and configure cardano-node
RUN git clone https://github.com/input-output-hk/cardano-node.git \
    && cd cardano-node \
    && git fetch --all --recurse-submodules --tags \
    && git checkout ${CARDANO_VERSION} \
    && cabal configure --with-compiler=ghc-${GHC_VERSION} \
    && echo -e "package cardano-crypto-praos\n  flags: -external-libsodium-vrf" > cabal.project.local

# build/install cardano
WORKDIR /src/cardano-node
RUN mkdir -p ~/.local/bin \
    && cabal install -j --installdir ~/.local/bin cardano-cli cardano-node

# compress binaries
RUN upx --best -o ~/cardano-node $(readlink -f ~/.local/bin/cardano-node)
RUN upx --best -o ~/cardano-cli $(readlink -f ~/.local/bin/cardano-cli)

RUN cardano-cli --version

CMD ["/bin/bash"]