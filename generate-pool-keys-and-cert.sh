#!/usr/bin/env sh
# See: https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/node_keys.html

set -e

CLI_VERSION='1.26.0'
uid=$(id -u ${USER})
gid=$(id -g ${USER})


runCliCmd() {
# --user "${uid}:${gid}" -v /etc/passwd:/etc/passwd
    docker run -v $(pwd):$(pwd) -w $(pwd) "dshiell15/cardano-cli:${CLI_VERSION}" "$@"
}

runCliCmdK8s() {
    kubectl -n cardano exec -t deploy/relay -- /usr/local/bin/cardano-cli "$@"
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
    local slotNo=$(runCliCmdK8s query tip --mainnet | jq .slotNo)
    local keyPeriod=$(expr "${slotNo}" / "${slotsPerKESPeriod}")

    echo $keyPeriod
    #runCliCmd node issue-op-cert \
#	      --kes-verification-key-file kes.vkey \
#	      --cold-signing-key-file cold.skey \
#	      --operational-certificate-issue-counter cold.counter \
#	      --kes-period "${keyPeriod}" \
#	      --out-file node.cert
}

setupCardanoConfigs() {
    kubectl -n cardano delete cm/configs
    kubectl -n cardano create configmap configs \
	--from-file=mainnet-topology.json=./configs/mainnet-topology.json \
	--from-file=mainnet-relay-topology.json=./configs/mainnet-relay-topology.json \
	--from-file=mainnet-config.json=./configs/mainnet-config.json \
	--from-file=mainnet-byron-genesis.json=./configs/mainnet-byron-genesis.json \
	--from-file=mainnet-shelley-genesis.json=./configs/mainnet-shelley-genesis.json \
	--from-file=testnet-topology.json=./configs/testnet-topology.json \
	--from-file=testnet-config.json=./configs/testnet-config.json \
	--from-file=testnet-byron-genesis.json=./configs/testnet-byron-genesis.json \
	--from-file=testnet-shelley-genesis.json=./configs/testnet-shelley-genesis.json
}

#setupCardanoConfigs
#generateColdKeys
generateOperationalCertificate
