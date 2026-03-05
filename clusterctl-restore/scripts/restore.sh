#!/bin/bash
set -eo pipefail
/etc/scripts/createkubectlconfig.sh
/etc/scripts/clusterctl_restore_from_s3.sh
