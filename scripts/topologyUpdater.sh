#!/usr/bin/env sh
# adapted from: https://github.com/cardano-community/guild-operators/blob/alpha/scripts/cnode-helper-scripts/topologyUpdater.sh

CNODE_HOSTNAME='rpi-cardano-pool.dyndns.org'
CNODE_PORT=3001
EKG_TIMEOUT=3
EKG_HOST=127.0.0.1
EKG_PORT=12788
GENESIS_JSON='configs/mainnet-shelley-genesis.json'
NWMAGIC=$(jq -r .networkMagic < ${GENESIS_JSON})
LOG_DIR='/data'
TOPOLOGY='topology.json'
MAX_PEERS=20
CUSTOM_PEERS="producer-0.cardano.svc.cluster.local:3001:1"

# set blockNo
if [[ ${TU_PUSH} = "Y" ]]; then
  fail_cnt=0
  while ! blockNo=$(curl -s -m ${EKG_TIMEOUT} -H 'Accept: application/json' "http://${EKG_HOST}:${EKG_PORT}/" 2>/dev/null | jq -er '.cardano.node.metrics.blockNum.int.val //0' ); do
    ((fail_cnt++))
    [[ ${fail_cnt} -eq 5 ]] && echo "5 consecutive EKG queries failed, aborting!"
    echo "(${fail_cnt}/5) Failed to grab blockNum from node EKG metrics, sleeping for 30s before retrying... (ctrl-c to exit)"
    sleep 30
  done
fi

# Note: 
# if you run your node in IPv4/IPv6 dual stack network configuration and want announced the
# IPv4 address only please add the -4 parameter to the curl command below  (curl -4 -s ...)
if [[ -n ${CNODE_HOSTNAME} && "${CNODE_HOSTNAME}" != "CHANGE ME" ]]; then
  T_HOSTNAME="&hostname=${CNODE_HOSTNAME}"
else
  T_HOSTNAME=''
fi

[[ ${TU_PUSH} = "Y" ]] && curl -s -f -4 "https://api.clio.one/htopology/v1/?port=${CNODE_PORT}&blockNo=${blockNo}&valency=${CNODE_VALENCY}&magic=${NWMAGIC}${T_HOSTNAME}" | tee -a "${LOG_DIR}"/topologyUpdater_lastresult.json
if [[ ${TU_FETCH} = "Y" ]]; then
  curl -s -f -4 -o "${TOPOLOGY}".tmp "https://api.clio.one/htopology/v1/fetch/?max=${MAX_PEERS}&magic=${NWMAGIC}"
  if [[ -n "${CUSTOM_PEERS}" ]]; then
    topo="$(cat "${TOPOLOGY}".tmp)"
    IFS='|' read -ra cpeers <<< "${CUSTOM_PEERS}"
    for p in "${cpeers[@]}"; do
      colons=$(echo "${p}" | tr -d -c ':' | awk '{print length}')
      case $colons in
        1) addr="$(cut -d: -f1 <<< "${p}")"
           port=$(cut -d: -f2 <<< "${p}")
           valency=1;;
        2) addr="$(cut -d: -f1 <<< "${p}")"
           port=$(cut -d: -f2 <<< "${p}")
           valency=$(cut -d: -f3 <<< "${p}");;
        *) echo "ERROR: Invalid Custom Peer definition '${p}'. Please double check CUSTOM_PEERS definition"
           exit 1;;
      esac
      topo=$(jq '.Producers += [{"addr": $addr, "port": $port|tonumber, "valency": $valency|tonumber}]' --arg addr "${addr}" --arg port ${port} --arg valency ${valency} <<< "${topo}")
    done
    echo "${topo}" | jq -r . >/dev/null 2>&1 && echo "${topo}" > "${TOPOLOGY}".tmp
  fi
  mv "${TOPOLOGY}".tmp "${TOPOLOGY}"
fi
exit 0
