#!/usr/bin/env sh
# See: https://cardano-foundation.gitbook.io/stake-pool-course/stake-pool-guide/stake-pool/register_stakepool

set -e

runCliCmd() {
    kubectl -n cardano exec -i statefulset/relay -- cardano-cli "$@"
}

# compute metadata hash from metadata url
computeMetadataHash() {
    local url="${1}"
    curl -sLo - "${url}" | runCliCmd stake-pool metadata-hash --pool-metadata-file /dev/stdin
}

# Ask user for their pool parameters
# NOTE: These should be validated to help the user and prevent errors. Some values have limits, some should be double checked...
promptPoolParams() {

    if [ ! -r ./configs/pool_pledge ]; then
	read -p "Pool pledge - Amount pool owner must keep delegated to the pool to ensure rewards. Higher pledge, higher rewards: " REPLY
	echo "${REPLY}" > ./configs/pool_pledge
    fi

    if [ ! -r ./configs/pool_cost ]; then
	read -p "Pool cost - Amount it costs pool owner to keep the pool running in lovelace (min 340000000 lovelace): " REPLY
	echo "${REPLY}" > ./configs/pool_cost
    fi

    if [ ! -r ./configs/pool_margin ]; then
	read -p "Pool margin - Percentage of rewards pool owner takes for profits (e.g. 0.03): " REPLY
	echo "${REPLY}" > ./configs/pool_margin
    fi

    if [ ! -r ./configs/pool_deposit_fee ]; then
	read -p "Pool deposit fee - Cost to register a stake pool in lovelace (see protocol-parameters.json): " REPLY
	echo "${REPLY}" > ./configs/pool_deposit_fee
    fi

    if [ ! -r ./configs/addr_balance ]; then
	read -p "Pool deposit fee - Cost to register a stake pool in lovelace (see protocol-parameters.json): " REPLY
	echo "${REPLY}" > ./configs/pool_deposit_fee
    fi

    if [ ! -r ./configs/metadata_hash ]; then
	read -p "Metadata URL - URL pointing to Pool metadata json: " REPLY
	echo "${REPLY}" > ./configs/metadata_url
	metadata_hash=$(computeMetadataHash "${REPLY}")
	echo "${metadata_hash}" > ./configs/metadata_hash
    fi

    if [ ! -r ./configs/relay_hostname ]; then
	read -p "Relay hostname - The public DNS name for your relay server(s): " REPLY
	echo "${REPLY}" > ./configs/relay_hostname
    fi

    if [ ! -r ./configs/relay_port ]; then
	read -p "Relay port - Listening port for relay server(s): " REPLY
	echo "${REPLY}" > ./configs/relay_port
    fi

    if [ ! -r ./configs/utxo_tx_in ]; then
	read -p "UTXO Tx In - UTXO hash for pool registration transaction: " REPLY
	echo "${REPLY}" > ./configs/utxo_tx_in
    fi

    if [ ! -r ./configs/utxo_tx_ix ]; then
	read -p "UTXO Tx Index - UTXO index for pool registration transaction: " REPLY
	echo "${REPLY}" > ./configs/utxo_tx_ix
    fi

    if [ ! -r ./configs/utxo_tx_out ]; then
	read -p "UTXO Tx Out - UTXO out for pool registration transaction: " REPLY
	echo "${REPLY}" > ./configs/utxo_tx_out
    fi
}

# setup configmap with required configs
setupPoolRegistrationParameters() {

    local cm_name="pool-configs"

    set +e
    kubectl -n cardano delete "cm/${cm_name}"
    set -e

    # setup pool parameters
    promptPoolParams
    
    kubectl -n cardano create configmap "${cm_name}" \
	    --from-file=pool_pledge=./configs/pool_pledge \
	    --from-file=pool_cost=./configs/pool_cost \
	    --from-file=pool_margin=./configs/pool_margin \
	    --from-file=pool_deposit_fee=./configs/pool_deposit_fee \
	    --from-file=relay_port=./configs/relay_port \
	    --from-file=metadata_url=./configs/metadata_url \
	    --from-file=metadata_hash=./configs/metadata_hash \
	    --from-file=relay_hostname=./configs/relay_hostname \
	    --from-file=utxo_tx_in=./configs/utxo_tx_in \
	    --from-file=utxo_tx_ix=./configs/utxo_tx_ix \
	    --from-file=utxo_tx_out=./configs/utxo_tx_out \
	    --from-file=create-cold-and-vrf-keys.sh=./scripts/create-cold-and-vrf-keys.sh \
	    --from-file=create-operational-cert.sh=./script/create-operational-cert.sh
	    
}

# setup configmap with required configs
setupNodeConfigs() {

    runCliCmd protocol-parameters --mainnet --out-file /dev/stdout > configs/protocol-parameters.json

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

setupNodeConfigs
setupPoolRegistrationParameters
