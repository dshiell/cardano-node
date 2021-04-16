#!/usr/bin/env sh

# Check the balance of your address.

### IMPORTANT: Will not work until relays are fully sync'd ***

runCliCmdRelay() {
    kubectl -n cardano exec -t statefulset/relay -- /usr/local/bin/cardano-cli "$@"
}

checkUTXOBalance() {

    if [ -f keys/payment.addr ]; then
	runCliCmdRelay query utxo \
		       --address $(cat keys/payment.addr) \
		       --mainnet
    else
	echo "Please run ./generate-pool-keys-and-cert.sh to generate pool keys, address, and cert first! They keys should be kept in cold storage, keep these safe!!!" 1>&2
	exit 1
    fi
}

checkUTXOBalance
