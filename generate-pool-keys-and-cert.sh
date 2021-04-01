#!/usr/bin/env sh
# See: https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/node_keys.html

set -e

CLI_VERSION='1.26.0'
uid=$(id -u ${USER})
gid=$(id -g ${USER})


runCliCmd() {
    docker run --user "${uid}:${gid}" -v /etc/passwd:/etc/passwd -v $(pwd):$(pwd) -w $(pwd) "dshiell15/cardano-cli:${CLI_VERSION}" "$@"
}

generateColdKeys() {
    runCliCmd node key-gen \
	      --cold-verification-key-file cold.vkey \
	      --cold-signing-key-file cold.skey \
	      --operational-certificate-issue-counter-file cold.counter
}

generateVrfKeyPair() {
    runCliCmd node key-gen-VRF \
	      --verification-key-file vrf.vkey \
	      --signing-key-file vrf.skey
}

generateKesPair() {
    runCliCmd node key-gen-KES \
	      --verification-key-file kes.vkey \
	      --signing-key-file kes.skey
}

generateOperationalCertificate() {
    local slotsPerKESPeriod=$(curl -sLo - https://hydra.iohk.io/build/5822084/download/1/mainnet-shelley-genesis.json | jq .slotsPerKESPeriod)
    local slotNo=$(runCliCmd query tip --mainnet | jq .slotNo)
    local keyPeriod=$(expr "${slotNo}" / "${slotsPerKESPeriod}")

    echo $keyPeriod
    #runCliCmd node issue-op-cert \
#	      --kes-verification-key-file kes.vkey \
#	      --cold-signing-key-file cold.skey \
#	      --operational-certificate-issue-counter cold.counter \
#	      --kes-period "${keyPeriod}" \
#	      --out-file node.cert
}

getConfigs() {
    #wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-config.json
    #wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-byron-genesis.json
    #wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-shelley-genesis.json
    #wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/testnet-topology.json

    curl -sLo mainnet-config.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-config.json
    curl -sLo mainnet-byron-genesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-byron-genesis.json
    curl -sLo mainnet-shelley-genesis.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-shelley-genesis.json
    curl -sLo mainnet-topology.json https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-topology.json
}

generateColdKeys
#generateOperationalCertificate
