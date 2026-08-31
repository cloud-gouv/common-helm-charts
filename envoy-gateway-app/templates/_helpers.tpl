{{/*
Expand the name of the chart.
*/}}
{{- define "envoy-gateway-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart/version label value
*/}}
{{- define "envoy-gateway-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Resolve namespace: use policy-level override, then global, then Release.Namespace
*/}}
{{- define "envoy-gateway-app.namespace" -}}
{{- $policy := index . 0 -}}
{{- $ctx := index . 1 -}}
{{- coalesce $policy.namespace $ctx.Values.global.namespace $ctx.Release.Namespace }}
{{- end }}

{{/*
Common labels applied to every resource
*/}}
{{- define "envoy-gateway-app.labels" -}}
helm.sh/chart: {{ include "envoy-gateway-app.chart" . }}
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
{{- define "envoy-gateway-app.annotations" -}}
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
{{- define "envoy-gateway-app.targetRef" -}}
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
{{- define "envoy-gateway-app.targetRefs" -}}
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

{{/*
Render a single parentRef block (no leading key)
*/}}
{{- define "envoy-gateway-app.parentRef" -}}
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
{{- define "envoy-gateway-app.backendRefs" -}}
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
{{- define "envoy-gateway-app.httpFilters" -}}
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
