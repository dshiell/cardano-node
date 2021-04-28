#!/bin/env sh

cardano-cli node key-gen-KES \
	    --verification-key-file kes.vkey \
	    --signing-key-file kes.skey

slotsPerKESPeriod=$(jq .slotsPerKESPeriod /configs/mainnet-shelley-genesis.json)
slot=$(cardano-cli query tip --mainnet | jq .slot)
kesPeriod=$(expr "${slot}" / "${slotsPerKESPeriod}")

cardano-cli node issue-op-cert \
	    --kes-verification-key-file kes.vkey \
	    --cold-signing-key-file cold.skey \
	    --operational-certificate-issue-counter-file cold.counter \
	    --kes-period ${kesPeriod} \
	    --out-file node-operational.cert
