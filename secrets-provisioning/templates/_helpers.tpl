{{/*
Return the ServiceAccount name used by secrets-provisioning job and RBAC.
*/}}
{{- define "sp.serviceAccountName" -}}
secret-writer
{{- end }}