# common-helm-charts

Ce repository publie les charts Helm en http avec pages:
- HTTP (Helm repository): `https://cloud-gouv.github.io/common-helm-charts`

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

## Utilisation en HTTP (GitHub Pages)

Ajouter le repo puis mettre a jour l'index local:

```bash
helm repo add common https://cloud-gouv.github.io/common-helm-charts
helm repo update
```

Lister les charts et versions:

```bash
helm search repo common --versions
```

Installer un chart:

```bash
helm install ingress-auth common/ingress-auth \
  --version 0.1.0 \
  --namespace ingress-system \
  --create-namespace
```

Rendre les manifests sans installer:

```bash
helm template ingress-auth common/ingress-auth \
  --version 0.1.0 \
  --namespace ingress-system
```

Telecharger un package:

```bash
helm pull common/ingress-auth --version 0.1.0
```

HTTP:

1st way:
```yaml
repositories:
- name: common
  url: https://cloud-gouv.github.io/common-helm-charts

releases:
- name: ingress-auth
  chart: common/ingress-auth
  version: 0.1.0 # Optionnal, default latest
```
2nd way:
```yaml
repositories:
  - name: common
    url: git+https://github.com/cloud-gouv/common-helm-charts.git?ref={{ .Values.common_charts.version | default "main" }}

releases:
- name: ingress-auth
  chart: common/ingress-auth
```

## Publication

- `.github/workflows/publish-http.yaml`: package les charts, genere `index.yaml`, puis publie sur GitHub Pages.