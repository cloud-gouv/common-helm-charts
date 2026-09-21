{{- define "osc-vm-power.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "osc-vm-power.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "osc-vm-power.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "osc-vm-power.labels" -}}
app.kubernetes.io/name: {{ include "osc-vm-power.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "osc-vm-power.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- .Values.serviceAccount.name | default (include "osc-vm-power.fullname" .) -}}
{{- else -}}
{{- .Values.serviceAccount.name | default "default" -}}
{{- end -}}
{{- end -}}

{{- define "osc-vm-power.imagePullSecretName" -}}
{{- .Values.imagePullSecret.name | default (printf "%s-regcred" (include "osc-vm-power.fullname" .)) -}}
{{- end -}}

{{- /* Secret de registre créé par le chart + ceux déjà présents dans le namespace,
       pour ne pas avoir à répéter son nom dans imagePullSecrets. */}}
{{- define "osc-vm-power.imagePullSecrets" -}}
{{- $secrets := .Values.imagePullSecrets | default list -}}
{{- if .Values.imagePullSecret.create -}}
{{- $secrets = prepend $secrets (dict "name" (include "osc-vm-power.imagePullSecretName" .)) -}}
{{- end -}}
{{- if $secrets -}}
imagePullSecrets:
{{ toYaml (uniq $secrets) }}
{{- end -}}
{{- end -}}
