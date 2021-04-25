#!/bin/sh

set -e

# \brief call cardano-cli in the cluster
runCliCmd() {
    kubectl -n cardano exec -i statefulset/relay -- /usr/local/bin/cardano-cli "$@"
}

# \brief Creates a raw pool registration transaction. Currently support only single tx input.
# \inputs positional arguments
#     1. tx_in - The UTxO Tx hash to use for the pool registration transaction
#     2. tx_ix - The UTxO Tx index to use for the pool registration transaction
#     3. tx_out - The payment/stake address
#     4. stake_verification_key_file - Contains the staking verification key
createStakeRegistrationTransactionRaw() {
    local tx_in="${1}"  # UTxO Tx hash
    local tx_ix="${2}"   # UTxO Tx Index
    local tx_out="${3}" # payment staking address
    local stake_verification_key_file="${4}"

    echo "${stake_verification_key_file}"
    
    # create stake registration certificate
    cat "${stake_verification_key_file}" | runCliCmd stake-address \
			   registration-certificate \
			   --stake-verification-key-file /dev/stdin \
			   --out-file /dev/stdout > stake.cert

    # query existing funds
    lovelace=$(runCliCmd query utxo --mainnet --address "${tx_out}" | grep "${tx_in}" | awk '{print $3}')

    echo "BALANCE: ${lovelace}"
    # build raw transaction
    cat stake.cert | runCliCmd transaction build-raw \
	      --tx-in "${tx_in}#${tx_ix}" \
	      --tx-out "${tx_out}+0" \
	      --ttl 0 \
	      --fee 0 \
	      --certificate-file /dev/stdin \
	      --out-file /dev/stdout > tx.raw

    # update the protocol parameters
    runCliCmd query protocol-parameters --mainnet --out-file /dev/stdout > configs/protocol-parameters.json

    # recreate configmap w/ protocol-parameters.json (how often does this change?)
    ./setup-configs.sh

    # calculate the minimum fee
    local min_fee=$(cat tx.raw | runCliCmd transaction calculate-min-fee \
					--tx-body-file /dev/stdin \
					--tx-in-count 1 \
					--tx-out-count 1 \
					--witness-count 1 \
					--protocol-params-file /config/protocol-parameters.json \
					--mainnet)

    echo "MIN_FEE: ${min_fee}"

    # set slot ttl to now + 2000 slots (seconds)
    local ttl=$(expr $(runCliCmd query tip --mainnet | jq .slot) + 2000)

    echo "TTL: ${ttl}"

    local stakePoolDeposit=$(jq .stakePoolDeposit configs/protocol-parameters.json)
    lovelace=$(expr "${lovelace}" - "${stakePoolDeposit}" - "${min_fee}")

    echo "NEW BALANCE: ${lovelace}"

    cat stake.cert | runCliCmd transaction build-raw \
              --tx-in "${tx_in}#${tx_ix}" \
              --tx-out "${tx_out}+${lovelace}" \
              --ttl "${ttl}" \
              --fee "${min_fee}" \
              --certificate-file /dev/stdin \
              --out-file /dev/stdout > pool_registration.raw
}

# takes utxo transaction (with #<TxIx> appended)
createStakeRegistrationTransactionRaw "${1}" "${2}" "${3}" "${4}"

