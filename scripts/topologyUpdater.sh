#!/usr/bin/env sh
# adapted from: https://github.com/cardano-community/guild-operators/blob/alpha/scripts/cnode-helper-scripts/topologyUpdater.sh
# This script should be run once an hour on your relay nodes.

CNODE_HOSTNAME="${CNODE_HOSTNAME:='ohana-pool.dyndns.org}"
CNODE_PORT="${CNODE_PORT:=3001}"
CNODE_VALENCY="${CNODE_VALENCY:=1}"
GENESIS_JSON="${GENESIS_JSON:=/home/cardano/configs/mainnet-shelley-genesis.json}"
TOPOLOGY="${TOPOLOGY:=/home/cardano/topology.json}"
MAX_PEERS="${MAX_PEERS:=20}"
CUSTOM_PEERS="${CUSTOM_PEERS:=cardano-producer-1.local:6000:1}"
NWMAGIC=$(jq -r .networkMagic < ${GENESIS_JSON})

node_alive_push() {

    blockNo=$(cardano-cli query tip --mainnet | jq .block)

    echo "BlockNo: ${blockNo}"
    #local fail_cnt=0
    #while ! blockNo=$(curl -s -m ${EKG_TIMEOUT} -H 'Accept: application/json' "http://${EKG_HOST}:${EKG_PORT}/" 2>/dev/null | jq -er '.cardano.node.metrics.blockNum.int.val //0' ); do
#	((fail_cnt++))
#	[[ ${fail_cnt} -eq 5 ]] && echo "5 consecutive EKG queries failed, aborting!"
#	echo "(${fail_cnt}/5) Failed to grab blockNum from node EKG metrics, sleeping for 30s before retrying... (ctrl-c to exit)"
#	sleep 30
 #   done

    local T_HOSTNAME=''
    if [ -n ${CNODE_HOSTNAME} ] && [ "${CNODE_HOSTNAME}" != "CHANGE ME" ]; then
	T_HOSTNAME="&hostname=${CNODE_HOSTNAME}"
    fi

    # Note: 
    # if you run your node in IPv4/IPv6 dual stack network configuration and want announced the
    # IPv4 address only please add the -4 parameter to the curl command below  (curl -4 -s ...)
    curl -s -f -4 "https://api.clio.one/htopology/v1/?port=${CNODE_PORT}&blockNo=${blockNo}&valency=${CNODE_VALENCY}&magic=${NWMAGIC}${T_HOSTNAME}"
}

update_topology() {

    curl -s -f -4 -o "${TOPOLOGY}".tmp "https://api.clio.one/htopology/v1/fetch/?max=${MAX_PEERS}&magic=${NWMAGIC}"

    if [ -n "${CUSTOM_PEERS}" ]; then
	local topo="$(cat "${TOPOLOGY}".tmp)"
	local cpeers=$(echo "${CUSTOM_PEERS}" | tr '|' ' ')
	for p in "${cpeers}"; do
	    local colons=$(echo "${p}" | awk -F':' '{ print NF-1 }')
	    case $colons in
		1) addr=$(echo "${p}" | cut -d: -f1)
		   port=$(echo "${p}" | cut -d: -f2)
		   valency=1;;
		2) addr=$(echo "${p}" | cut -d: -f1)
		   port=$(echo "${p}" | cut -d: -f2)
		   valency=$(echo "${p}" | cut -d: -f3);;
		*) echo "ERROR: Invalid Custom Peer definition '${p}'. Please double check CUSTOM_PEERS definition"
		   exit 1;;
	    esac
	    topo=$(echo "${topo}" | jq '.Producers += [{"addr": $addr, "port": $port|tonumber, "valency": $valency|tonumber}]' --arg addr "${addr}" --arg port ${port} --arg valency ${valency})
	done
	echo "${topo}" | jq -r . >/dev/null 2>&1 && echo "${topo}" > "${TOPOLOGY}".tmp
    fi
    mv "${TOPOLOGY}".tmp "${TOPOLOGY}"
}

node_alive_push
update_topology

exit 0
