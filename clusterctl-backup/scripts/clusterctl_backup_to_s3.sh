#!/bin/bash
set -eo pipefail

echo "# Start $(basename $0)"
export exit_code=0

cleanup() {
  ret=$?
  echo "Cleaning up..."
  rm -rf "${TMPBACKUPDIR}"
  exit ${ret}
}
trap cleanup INT EXIT

if [ -z "${KUBECONFIG}" ]; then
  echo "Error: KUBECONFIG not set"
  exit_code=1
fi

if [ -z "${AWS_BUCKET_NAME}" ]; then
  echo "Error: AWS_BUCKET_NAME not set"
  exit_code=1
fi
if [ -z "${AWS_SECRET_ACCESS_KEY}" ] || \
   [ -z "${AWS_ACCESS_KEY_ID}" ] || \
   [ -z "${AWS_ENDPOINT_URL}" ] || \
   [ -z "${AWS_DEFAULT_REGION}" ] ; then
  echo "Error: AWS_ variables not set"
  exit_code=1
fi
if [ -z "${SOPS_AGE_RECIPIENTS}" ]; then
  echo "Error: SOPS_AGE_RECIPIENTS not set"
  exit_code=1
fi
[ "$exit_code" -gt 0 ] && exit $exit_code

echo "# Create tmp backup dirs"
export TMPBACKUPDIR="/backup/clusterctl_backup"
BACKUP_TIMESTAMP="$(date +%Y-%m-%d-%H-%M)"
BACKUP_PREFIX_DIR=${TMPBACKUPDIR}/${AWS_BUCKET_NAME}/${BACKUP_TIMESTAMP}
BACKUP_CLUSTERS_PATH="${BACKUP_PREFIX_DIR}/dump"
BACKUP_CLUSTERS_ENCRYPTED_DIR="${BACKUP_PREFIX_DIR}/encrypted"
BACKUP_CLUSTERS_ARCHIVES_DIR="${BACKUP_PREFIX_DIR}/archives"

mkdir -p $TMPBACKUPDIR
mkdir -p $BACKUP_CLUSTERS_PATH $BACKUP_CLUSTERS_ENCRYPTED_DIR $BACKUP_CLUSTERS_ARCHIVES_DIR
cd $TMPBACKUPDIR

echo "# Get clusters list"
list_cluster="$(kubectl get clusters -n default -o=custom-columns=NAME:.metadata.name --no-headers=true  |grep -v -- '-mgmt-')"
[ -z "$list_cluster" ] && exit 1

echo "# Dump clusters data"
clusterctl move -n default --to-directory $BACKUP_CLUSTERS_PATH

BACKUP_FILE_COUNT="$( find $BACKUP_CLUSTERS_PATH -type f |wc -l )"
echo " # $BACKUP_FILE_COUNT files"
[ "$BACKUP_FILE_COUNT" -gt 0 ] || exit 1

echo "# Extract each app cluster data"
for cluster in ${list_cluster}; do
  echo "Encrypt $cluster data"
  export BACKUP_ENCRYPTED_PATH="${BACKUP_CLUSTERS_ENCRYPTED_DIR}/${cluster}"
  mkdir -p $BACKUP_ENCRYPTED_PATH

  # encrypt cluster files
  ( cd ${BACKUP_CLUSTERS_PATH} && \
    find . -type f -regex ".*${cluster}.*" \
      -exec echo "sops -e ${BACKUP_CLUSTERS_PATH}/{} > ${BACKUP_ENCRYPTED_PATH}/\$(basename {} .yaml).enc.yaml " \;
  ) | bash

  BACKUP_NAME="${cluster}.tar.gz"
  BACKUP_NAME_SHA="${cluster}.tar.gz.sha1"

  echo "# Create backup archive: ${BACKUP_NAME} ${BACKUP_NAME_SHA}"
  ( cd $BACKUP_ENCRYPTED_PATH && tar cvzf "${BACKUP_CLUSTERS_ARCHIVES_DIR}/${BACKUP_NAME}" . )
  ( cd ${BACKUP_CLUSTERS_ARCHIVES_DIR} && sha1sum "${BACKUP_NAME}" > "${BACKUP_NAME_SHA}" )
done

echo "# s3: Start upload to s3://${AWS_BUCKET_NAME}/${BACKUP_TIMESTAMP}"
# Bug outscale/OOS - aws cli
#   ref: https://docs.outscale.com/fr/userguide/Avertissement-sur-la-compatibilit%C3%A9-des-SDK-et-de-la-CLI-AWS.html#_solutions_de_contournement
export AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED
export AWS_RESPONSE_CHECKSUM_VALIDATION=WHEN_REQUIRED

echo "# s3: Create bucket s3://${AWS_BUCKET_NAME}"
aws s3 ls "s3://${AWS_BUCKET_NAME}" 2>&1 1>/dev/null || \
  aws s3 mb "s3://${AWS_BUCKET_NAME}"

( set -eo pipefail
cd ${BACKUP_CLUSTERS_ARCHIVES_DIR}
find * -type f -regex ".*.tar.gz.*" | while read backup ; do
  echo "# s3: start upload s3://${AWS_BUCKET_NAME}/${BACKUP_TIMESTAMP}/${backup}"
  aws s3 ls "s3://${AWS_BUCKET_NAME}/${BACKUP_TIMESTAMP}/${backup}" && echo "# Warning: overwrite s3://${AWS_BUCKET_NAME}/${BACKUP_TIMESTAMP}/${backup}"
  aws s3 cp "${BACKUP_CLUSTERS_ARCHIVES_DIR}/${backup}" "s3://${AWS_BUCKET_NAME}/${BACKUP_TIMESTAMP}/${backup}"
  if [ $? -gt 0 ] ;then
     echo "# Error: s3://${AWS_BUCKET_NAME}/${BACKUP_TIMESTAMP}/${backup} not backuped !"
     exit 1
  fi
  echo "# s3: end upload s3://${AWS_BUCKET_NAME}/${BACKUP_TIMESTAMP}/${backup}"
done
) || exit 1
aws s3 ls --summarize --recursive "s3://${AWS_BUCKET_NAME}/${BACKUP_TIMESTAMP}"

echo "# End $(basename $0)"
