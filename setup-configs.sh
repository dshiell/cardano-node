#!/usr/bin/env sh
# See: https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/node_keys.html

set -e

# setup configmap with required configs
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
	--from-file=testnet-shelley-genesis.json=./configs/testnet-shelley-genesis.json \
	--from-file=protocol-parameters.json=./configs/protocol-parameters.json
}

setupCardanoConfigs
