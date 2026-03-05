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
if [ -z "${SOPS_AGE_KEY}" ]; then
  echo "Error: SOPS_AGE_KEY not set"
  exit_code=1
fi
[ "$exit_code" -gt 0 ] && exit $exit_code


echo "# Get timestamp backup"
aws s3 ls s3://${AWS_BUCKET_NAME} || exit 1
if [ ! -z "$RESTORE_TIMESTAMP" ]; then
  RESTORE_TIMESTAMP="$(aws s3 ls s3://${AWS_BUCKET_NAME}/${RESTORE_TIMESTAMP} | awk ' NF > 1 { print $2 } ' | sort -nr | cut -d '/' -f1|head -1)"
else
  RESTORE_TIMESTAMP="$(aws s3 ls s3://${AWS_BUCKET_NAME} | awk ' NF > 1 { print $2 } ' | sort -nr | cut -d '/' -f1|head -1)"
fi
[ -z "$RESTORE_TIMESTAMP" ] && exit 1

echo "# Create tmp restore dirs"
RESTORE_TMP_DIR="/backup/restore"
RESTORE_PREFIX_DIR="${RESTORE_TMP_DIR}/${AWS_BUCKET_NAME}/${RESTORE_TIMESTAMP}"
RESTORE_CLUSTERS_ARCHIVES_DIR="${RESTORE_PREFIX_DIR}/archives"
RESTORE_CLUSTERS_ENCRYPTED_DIR="${RESTORE_PREFIX_DIR}/encrypted"
RESTORE_CLUSTERS_PATH="${RESTORE_PREFIX_DIR}/dump"

mkdir -p $RESTORE_TMP_DIR
mkdir -p $RESTORE_PREFIX_DIR $RESTORE_CLUSTERS_ARCHIVES_DIR $RESTORE_CLUSTERS_ENCRYPTED_DIR $RESTORE_CLUSTERS_PATH

echo "# s3: restore s3://${AWS_BUCKET_NAME}/${RESTORE_TIMESTAMP}"
cd ${RESTORE_CLUSTERS_ARCHIVES_DIR}
aws s3 cp s3://${AWS_BUCKET_NAME}/$RESTORE_TIMESTAMP $RESTORE_CLUSTERS_ARCHIVES_DIR --recursive

sha1sum -c *.sha1 || exit 1

list_archives="$(find * -type f -regex '.*.tar.gz')"
[ -z "$list_archives" ] && exit 1

for archive in ${list_archives}; do
  echo "# restore $archive"
  cluster="$(basename $archive .tar.gz)"

  export RESTORE_ENCRYPTED_PATH="${RESTORE_CLUSTERS_ENCRYPTED_DIR}/${cluster}"
  mkdir -p ${RESTORE_ENCRYPTED_PATH}

  tar -zxvf $archive -C ${RESTORE_ENCRYPTED_PATH}

  RESTORE_ENCRYPTED_FILE_COUNT="$(find ${RESTORE_ENCRYPTED_PATH} -type f |wc -l)"
  [ "$RESTORE_ENCRYPTED_FILE_COUNT" -eq 0 ] && exit 1

  # decrypt cluster files
  ( cd ${RESTORE_ENCRYPTED_PATH} && \
    find . -type f -regex ".*${cluster}.*" \
      -exec echo "sops -d ${RESTORE_ENCRYPTED_PATH}/{} > ${RESTORE_CLUSTERS_PATH}/\$(basename {} .enc.yaml).yaml " \;
  ) | bash

  RESTORE_FILE_COUNT="$(find ${RESTORE_CLUSTERS_PATH} -type f |wc -l)"
  [ "$RESTORE_FILE_COUNT" -eq 0 ] && exit 1

done

echo "# start clusterctl move"
clusterctl move  -v 10 -n default --from-directory $RESTORE_CLUSTERS_PATH

echo "# End $(basename $0)"
