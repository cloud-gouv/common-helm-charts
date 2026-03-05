#!/bin/bash
set -eo pipefail
/etc/scripts/createkubectlconfig.sh
/etc/scripts/clusterctl_backup_to_s3.sh
/etc/scripts/clusterctl_backup_retention.sh
