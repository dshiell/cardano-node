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
    local pod=$(kubectl -n cardano get pod -l job-name=generate-pool-keys --output=jsonpath='{.items[*].metadata.name}')
    echo "Waiting for job to start..."
    kubectl -n cardano wait --timeout=30s --for=condition=Ready "pod/${pod}"
    mkdir -p keys
    kubectl cp "cardano/${pod}:/keys" keys
    echo "Successfully created cold keys, vrf keys, and key keys. See ./keys directory."
    kubectl delete -f k8s/generate-keys-job.yaml
}

generateOperationalCertificate() {
    local slotsPerKESPeriod=$(jq .slotsPerKESPeriod configs/mainnet-shelley-genesis.json)
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

generateKeys
generateOperationalCertificate
