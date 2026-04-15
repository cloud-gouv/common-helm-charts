# common-helm-charts
## Prerequis

- Helm 3

## Charts disponibles

- `argocd-apps`
- `cert-manager-issuers`
- `client-namespaces`
- `clusterctl-backup`
- `clusterctl-restore`
- `external-secrets`
- `grafana-dashboards`
- `ingress-auth`
- `matrix-receiver`
- `minio-backup`
- `minio-tenant`
- `raw`
- `rclone`
- `secrets`

```yaml
releases:
  - name: my-db
    chart: oci://registry-1.docker.io/bitnamicharts/postgresql
    version: 12.5.1
    values:
      - values.yaml
```