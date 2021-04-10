#!/bin/sh
set -euxo pipefail

echo "* * * * * /scripts/topologyUpdater.sh" > /etc/cron.d/topology-updater

# run once at startup to test
/scripts/topologyUpdater.sh
cron -f
