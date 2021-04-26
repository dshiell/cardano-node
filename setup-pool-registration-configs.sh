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
	    --from-file=relay_port=./configs/relay_port \
	    --from-file=metadata_url=./configs/metadata_url \
	    --from-file=metadata_hash=./configs/metadata_hash \
	    --from-file=relay_hostname=./configs/relay_hostname
}

setupPoolRegistrationParameters
