
FROM ubuntu:20.04

ARG CABAL_VERSION=3.4.0.0
ARG GHC_VERSION=8.10.2
ARG CARDANO_VERSION=1.26.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    haskell-platform \
    build-essential \
    libsodium-dev \
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
    llvm \
    libnuma-dev

# potentially install llvm-9

ENV PATH="~/.local/bin:${PATH}"

WORKDIR /src
 
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
    
# build cardano-node
RUN git clone https://github.com/input-output-hk/cardano-node.git \
    && cd cardano-node \
    && git fetch --all --recurse-submodules --tags \
    && git checkout ${CARDANO_VERSION} \
    && /root/.cabal/bin/cabal configure --with-compiler=ghc-${GHC_VERSION} \
    && echo -e "package cardano-crypto-praos\n  flags: -external-libsodium-vrf" > cabal.project.local \
    && /root/.cabal/gin/cabal build all \
    && mkdir -p ~/.local/bin \
    && cp -p ~/cardano-node/dist-newstyle/build/aarch64-linux/ghc-${GHC_VERSION}/cardano-node-${CARDANO_VERSION}/x/cardano-node/build/cardano-node/cardano-node ~/.local/bin/ \
    && cp -p ~/cardano-node/dist-newstyle/build/aarch64-linux/ghc-${GHC_VERSION}/cardano-cli-${CARDANO_VERSION}/x/cardano-cli/build/cardano-cli/cardano-cli ~/.local/bin/ \
    && cardano-cli --version
    
    