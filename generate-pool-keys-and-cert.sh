#!/usr/bin/env sh
# See: https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/node_keys.html

set -e

CLI_VERSION='1.26.1'
uid=$(id -u ${USER})
gid=$(id -g ${USER})

runCliCmdRelay() {
    kubectl -n cardano exec -t statefulset/relay -- /usr/local/bin/cardano-cli "$@"
}

# generate stake pool keys
generateKeys() {
    kubectl apply -f k8s/generate-keys-job.yaml
#    sleep 3
    local pod=$(kubectl -n cardano get pod -l job-name=generate-pool-keys --output=jsonpath='{.items[*].metadata.name}')
    echo "Waiting for job to start..."
    kubectl -n cardano wait --timeout=30s --for=condition=Ready "pod/${pod}"
    mkdir -p keys
    kubectl cp "cardano/${pod}:/job" keys
    echo "Successfully created cold keys, vrf keys, and key keys. See ./keys directory."
    kubectl delete -f k8s/generate-keys-job.yaml
}

generateOperationalCertificate() {
    local slotsPerKESPeriod=$(curl -sLo - https://hydra.iohk.io/build/5822084/download/1/mainnet-shelley-genesis.json | jq .slotsPerKESPeriod)
    local slot=$(runCliCmdRelay query tip --mainnet | jq .slot)
    local keyPeriod=$(expr "${slot}" / "${slotsPerKESPeriod}")

    echo $keyPeriod
    #runCliCmd node issue-op-cert \
#	      --kes-verification-key-file kes.vkey \
#	      --cold-signing-key-file cold.skey \
#	      --operational-certificate-issue-counter cold.counter \
#	      --kes-period "${keyPeriod}" \
#	      --out-file node.cert
}

setupCardanoConfigs() {
    set +e
    kubectl -n cardano delete cm/configs
    set -e
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

setupCardanoConfigs
generateKeys
#generateVrfKeyPair
#generateKesPair
generateOperationalCertificate
