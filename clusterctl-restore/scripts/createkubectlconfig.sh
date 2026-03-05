#!/bin/bash
set -eo pipefail
echo "# Start $(basename $0)"
[ -z "${KUBECONFIG}" ] && exit 1
mkdir -p "$(dirname ${KUBECONFIG})"

SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
CACERT=${SERVICEACCOUNT}/ca.crt
TOKEN=$(cat ${SERVICEACCOUNT}/token)
KUBERNETES_CONTEXT=default
USERACCOUNT=backup

cat << EOF > ${KUBECONFIG}
  apiVersion: v1
  kind: Config
  current-context: ${KUBERNETES_CONTEXT}
  clusters:
  - name: kubernetes
    cluster:
      certificate-authority: ${CACERT}
      server: https://${KUBERNETES_SERVICE_HOST}:$KUBERNETES_SERVICE_PORT_HTTPS
  users:
  - name: ${USERACCOUNT}
    user:
      token: ${TOKEN}
  contexts:
  - name: ${KUBERNETES_CONTEXT}
    context:
      cluster: kubernetes
      user: ${USERACCOUNT}
EOF
echo "# End $(basename $0)"

