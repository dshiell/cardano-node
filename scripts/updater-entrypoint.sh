#!/bin/sh
set -euxo pipefail

echo "* * * * * /scripts/sayhi.sh" > /var/spool/cron/crontabs/root
crond -f
