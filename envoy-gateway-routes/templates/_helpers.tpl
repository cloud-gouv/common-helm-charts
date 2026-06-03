{{/*
Chart name
*/}}
{{- define "envoy-gateway-routes.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Chart label value
*/}}
{{- define "envoy-gateway-routes.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Resolve namespace: resource-level → global → Release.Namespace
*/}}
{{- define "envoy-gateway-routes.namespace" -}}
{{- $resource := index . 0 -}}
{{- $ctx     := index . 1 -}}
{{- coalesce $resource.namespace $ctx.Values.global.namespace $ctx.Release.Namespace }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "envoy-gateway-routes.labels" -}}
helm.sh/chart: {{ include "envoy-gateway-routes.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: envoy-gateway
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Merge global + local annotations
*/}}
{{- define "envoy-gateway-routes.annotations" -}}
{{- $global := .globalAnnotations | default dict -}}
{{- $local  := .localAnnotations  | default dict -}}
{{- $merged := merge $local $global -}}
{{- if $merged }}
{{- toYaml $merged }}
{{- end }}
{{- end }}

{{/*
Render a single parentRef block (no leading key)
*/}}
{{- define "envoy-gateway-routes.parentRef" -}}
- name: {{ .name }}
  {{- with .namespace }}
  namespace: {{ . }}
  {{- end }}
  {{- with .group }}
  group: {{ . }}
  {{- end }}
  {{- with .kind }}
  kind: {{ . }}
  {{- end }}
  {{- with .sectionName }}
  sectionName: {{ . }}
  {{- end }}
  {{- with .port }}
  port: {{ . }}
  {{- end }}
{{- end }}

{{/*
Render backendRefs list
*/}}
{{- define "envoy-gateway-routes.backendRefs" -}}
{{- range . }}
- name: {{ .name }}
  {{- with .namespace }}
  namespace: {{ . }}
  {{- end }}
  port: {{ .port }}
  {{- with .weight }}
  weight: {{ . }}
  {{- end }}
  {{- with .group }}
  group: {{ . }}
  {{- end }}
  {{- with .kind }}
  kind: {{ . }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Render HTTPRoute filters
*/}}
{{- define "envoy-gateway-routes.httpFilters" -}}
{{- range . }}
- type: {{ .type }}
  {{- if eq .type "RequestRedirect" }}
  requestRedirect:
    {{- with .requestRedirect.scheme }}
    scheme: {{ . }}
    {{- end }}
    {{- with .requestRedirect.hostname }}
    hostname: {{ . }}
    {{- end }}
    {{- with .requestRedirect.port }}
    port: {{ . }}
    {{- end }}
    {{- with .requestRedirect.statusCode }}
    statusCode: {{ . }}
    {{- end }}
    {{- with .requestRedirect.path }}
    path:
      type: {{ .type }}
      {{- if eq .type "ReplaceFullPath" }}
      replaceFullPath: {{ .replaceFullPath }}
      {{- end }}
      {{- if eq .type "ReplacePrefixMatch" }}
      replacePrefixMatch: {{ .replacePrefixMatch }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if eq .type "URLRewrite" }}
  urlRewrite:
    {{- with .urlRewrite.hostname }}
    hostname: {{ . }}
    {{- end }}
    {{- with .urlRewrite.path }}
    path:
      type: {{ .type }}
      {{- if eq .type "ReplaceFullPath" }}
      replaceFullPath: {{ .replaceFullPath }}
      {{- end }}
      {{- if eq .type "ReplacePrefixMatch" }}
      replacePrefixMatch: {{ .replacePrefixMatch }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if eq .type "RequestHeaderModifier" }}
  requestHeaderModifier:
    {{- with .requestHeaderModifier.set }}
    set:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .requestHeaderModifier.add }}
    add:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .requestHeaderModifier.remove }}
    remove:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- if eq .type "ResponseHeaderModifier" }}
  responseHeaderModifier:
    {{- with .responseHeaderModifier.set }}
    set:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .responseHeaderModifier.add }}
    add:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .responseHeaderModifier.remove }}
    remove:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- if eq .type "RequestMirror" }}
  requestMirror:
    backendRef:
      name: {{ .requestMirror.backendRef.name }}
      port: {{ .requestMirror.backendRef.port }}
      {{- with .requestMirror.backendRef.namespace }}
      namespace: {{ . }}
      {{- end }}
    {{- with .requestMirror.percent }}
    percent: {{ . }}
    {{- end }}
  {{- end }}
  {{- if eq .type "ExtensionRef" }}
  extensionRef:
    group: {{ .extensionRef.group }}
    kind: {{ .extensionRef.kind }}
    name: {{ .extensionRef.name }}
  {{- end }}
{{- end }}
{{- end }}
