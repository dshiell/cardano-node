#!/bin/env sh

cardano-cli stake-pool registration-certificate \
	    --cold-verification-key-file cold.vkey \
	    --vrf-verification-key-file vrf.vkey \
	    --pool-pledge ${POOL_PLEDGE} \
	    --pool-cose ${POOL_COST} \
	    --pool-margin ${POOL_MARGIN} \
	    --pool-reward-account-verification-key-file stake.vkey \
	    --pool-owner-stake-verification-key-file stake.vkey \
	    --single-host-pool-relay ${RELAY_HOSTNAME} \
	    --pool-relay-port ${RELAY_PORT} \
	    --metadata-url ${METADATA_URL} \
	    --metadata-hash ${METADATA_HASH} \
	    --out-file pool-registration.cert

cardano-cli stake-address delegation-certificate \
	    --stake-verification-key-file stake.vkey \
	    --cold-verification-key-file cold.vkey \
	    --out-file delegation.cert

cardano-cli transaction build-raw \
	    --tx-in "${UTXO_TX_IN}#${UTXO_TX_IX}" \
	    --tx-out "${UTXO_TX_OUT}+0" \
	    --ttl 0 \
	    --fee 0 \
	    --certificate-file pool-registration.cert \
	    --certificate-file delegation.cert \
	    --out-file pool-registration-tx.raw \

min_fee=$(cardano-cli transaction calculate-min-free \
		      --tx-body-file pool-registration-tx.raw \
		      --tx-in-count 1 \
		      --tx-out-count 1 \
		      --witness-count 1 \
		      --protocol-params-file /configs/protocol-parameters.json \
		      --mainnet)

new_balance=$(expr ${POOL_BALANCE} - ${POOL_DEPOSIT_FEE} - ${min_fee})

cardano-cli transaction build-raw \
	    --tx-in "${UTXO_TX_IN}#${UTXO_TX_IX}" \
	    --tx-out "$(UTXO_TX_OUT)+${new_balance}" \
	    --ttl 200000 \
	    --fee ${min_fee} \
	    --certificate-file pool-registration.cert \
	    --certificate-file delegation.cert \
	    --out-file pool-registration-tx.raw
