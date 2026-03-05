{{/*
Expand the name of the chart.
*/}}
{{- define "argocd-apps.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "argocd-apps.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "argocd-apps.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "argocd-apps.labels" -}}
helm.sh/chart: {{ include "argocd-apps.chart" . }}
{{ include "argocd-apps.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "argocd-apps.selectorLabels" -}}
app.kubernetes.io/name: {{ include "argocd-apps.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "argocd-apps.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "argocd-apps.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Argocd Application functions
*/}}

{{- define "argocd-apps.defaultSourcePath" -}}
{{- $path := "default/path" }}
{{- if and (hasKey .Values.source "path") (not (empty .Values.source.path)) }}
{{- $path = .Values.source.path }}
{{- end }}
{{- $path }}
{{- end }}

{{- define "argocd-apps.defaultSourceTargetRevision" -}}
{{- $targetRevision := "main" }}
{{- if and (hasKey .Values.source "targetRevision") (not (empty .Values.source.targetRevision)) }}
{{- $targetRevision = .Values.source.targetRevision }}
{{- end }}
{{- $targetRevision }}
{{- end }}

{{/*
  spec.destination.name: get name from .data or .default
*/}}
{{- define "argocd-apps.defaultDestinationName" -}}
{{- $data := .data -}}
{{- $default := .default -}}
{{- if (typeIs "map[string]interface {}" $data) }}
{{- if and (hasKey $data "destination") (hasKey $data.destination "name") }}
{{- $data.destination.name |quote }}
{{- else }}
{{- $default | quote }}
{{- end }}
{{- else }}
{{- $default | quote }}
{{- end }}
{{- end }}

{{- define "argocd-apps.defaultEnvironment" -}}
{{- $data := .data -}}
{{- $default := .default -}}
{{- if (typeIs "map[string]interface {}" $data) }}
{{- if and (hasKey $data "environment") }}
{{- $data.environment |quote }}
{{- else }}
{{- $default | quote }}
{{- end }}
{{- else }}
{{- $default | quote }}
{{- end }}
{{- end }}
