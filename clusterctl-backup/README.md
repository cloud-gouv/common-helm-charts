A Helm chart for manage backup:
  - clusterapi object definition

Based on following env variables:
```
  AWS_BUCKET_NAME
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AWS_ENDPOINT_URL
  AWS_DEFAULT_REGION
  # in backup mode, public age key
  SOPS_AGE_RECIPIENTS
  # in restore mode, secret age key
  SOPS_AGE_KEY
```
Variables must defined in secrets.enc.yaml

