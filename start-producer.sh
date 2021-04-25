#!/bin/sh

# set up secrets so we can start the block producer node
kubectl -n cardano delete secret/keys
kubectl -n cardano create secret generic keys \
	--from-file=cold.counter=keys/cold.counter \
	--from-file=kes.skey=keys/kes.skey \
	--from-file=vrf.skey=keys/vrf.skey \
	--from-file=node.cert=keys/node.cert

kubectl apply -f k8s/producer.yaml
