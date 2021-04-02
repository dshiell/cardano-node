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

setupCardanoConfigs() {
    if [ -n ${TESTMODE} ]; then
	kubectl -n cardano create configmap configs \
	    --from-file=testnet-topology=./testnet-topology.json \
	    --from-file=testnet-config=./testnet-config.json \
	    --from-file=testnet-byron-genesis=./testnet-byron-genesis.json \
	    --from-file=testnet-shelley-genesis=./testnet-shelley-genesis.json
    else
	kubectl -n cardano create configmap configs \
	    --from-file=mainnet-topology=./mainnet-topology.json \
	    --from-file=mainnet-config=./mainnet-config.json \
	    --from-file=mainnet-byron-genesis=./mainnet-byron-genesis.json \
	    --from-file=mainnet-shelley-genesis=./mainnet-shelley-genesis.json
    fi
}

generateColdKeys
#generateOperationalCertificate
