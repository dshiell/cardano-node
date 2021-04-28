#!/bin/env/ sh

# Creates
# - cold keys
# - vrf keys
cardano-cli node key-gen \
	    --cold-verification-key-file cold.vkey \
	    --cold-signing-key-file cold.skey \
	    --operational-certificate-issue-counter-file cold.counter

cardano-cli node key-gen-VRF \
	    --verification-key-file vrf.vkey \
	    --signing-key-file vrf.skey

