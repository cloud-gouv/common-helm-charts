{{/*
Expand the name of the chart.
*/}}
{{- define "envoy-gateway-policies.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart/version label value
*/}}
{{- define "envoy-gateway-policies.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Resolve namespace: use policy-level override, then global, then Release.Namespace
*/}}
{{- define "envoy-gateway-policies.namespace" -}}
{{- $policy := index . 0 -}}
{{- $ctx := index . 1 -}}
{{- coalesce $policy.namespace $ctx.Values.global.namespace $ctx.Release.Namespace }}
{{- end }}

{{/*
Common labels applied to every resource
*/}}
{{- define "envoy-gateway-policies.labels" -}}
helm.sh/chart: {{ include "envoy-gateway-policies.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: envoy-gateway
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Merge global annotations with resource-specific annotations
*/}}
{{- define "envoy-gateway-policies.annotations" -}}
{{- $global := .globalAnnotations | default dict -}}
{{- $local := .localAnnotations | default dict -}}
{{- $merged := merge $local $global -}}
{{- if $merged }}
{{- toYaml $merged }}
{{- end }}
{{- end }}

{{/*
Render a targetRef block
*/}}
{{- define "envoy-gateway-policies.targetRef" -}}
targetRef:
  group: {{ .group | default "gateway.networking.k8s.io" }}
  kind: {{ .kind }}
  name: {{ .name }}
  {{- if .namespace }}
  namespace: {{ .namespace }}
  {{- end }}
  {{- if .sectionName }}
  sectionName: {{ .sectionName }}
  {{- end }}
{{- end }}

{{/*
Render targetRefs (plural, for policies supporting multiple targets)
*/}}
{{- define "envoy-gateway-policies.targetRefs" -}}
targetRefs:
{{- range . }}
  - group: {{ .group | default "gateway.networking.k8s.io" }}
    kind: {{ .kind }}
    name: {{ .name }}
    {{- if .namespace }}
    namespace: {{ .namespace }}
    {{- end }}
    {{- if .sectionName }}
    sectionName: {{ .sectionName }}
    {{- end }}
{{- end }}
{{- end }}
