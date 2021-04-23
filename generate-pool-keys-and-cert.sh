#!/usr/bin/env sh
# See: https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/node_keys.html

set -e

runCliCmd() {
    kubectl -n cardano exec -t statefulset/relay -- /usr/local/bin/cardano-cli "$@"
}

# generate stake pool keys and operation certificate
generateKeysAndOperationalCertificate() {
    local slotsPerKESPeriod=$(jq .slotsPerKESPeriod configs/mainnet-shelley-genesis.json)
    local slot=$(runCliCmd query tip --mainnet | jq .slot)
    local kesPeriod=$(expr "${slot}" / "${slotsPerKESPeriod}")

    echo KES_PERIOD="${kesPeriod}"
    
    set +e
    kubectl -n cardano delete cm/keyperiod
    kubectl delete -f k8s/generate-keys-job.yaml
    set -e
    kubectl -n cardano create configmap kesperiod --from-literal=kesPeriod="${kesPeriod}"

    kubectl apply -f k8s/generate-keys-job.yaml
    local pod=$(kubectl -n cardano get pod -l job-name=generate-pool-keys --output=jsonpath='{.items[*].metadata.name}')
    echo "Waiting for job to start..."
    kubectl -n cardano wait --timeout=30s --for=condition=Ready "pod/${pod}"
    mkdir -p keys
    kubectl cp "cardano/${pod}:/keys" keys
    echo "Successfully created cold keys, vrf keys, and key keys. See ./keys directory."
    kubectl delete -f k8s/generate-keys-job.yaml
    kubectl -n cardano delete cm/kesperiod
}

generateKeysAndOperationalCertificate
