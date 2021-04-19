#!/bin/sh

kubectl -n cardano exec svc/relay -it -- cardano-cli query protocol-parameters --mainnet --out-file /dev/stdout
