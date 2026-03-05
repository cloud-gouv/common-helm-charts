{{/*
Expand the name of the chart.
*/}}
{{- define "minio-backup.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
