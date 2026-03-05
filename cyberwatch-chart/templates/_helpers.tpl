{{- define "cbw.env-secret" -}}
{{- if and .secretRef .secretRef.name .secretRef.key }}
- name: {{ .env }}
  valueFrom:
    secretKeyRef:
      name: {{ .secretRef.name }}
      key: {{ .secretRef.key }}
      {{- if .optional }}
      optional: true
      {{- end }}
{{- else }}
- name: {{ .env }}
  valueFrom:
    secretKeyRef:
      key: {{ .key }}
      name: cbw-secrets
      {{- if .optional }}
      optional: true
      {{- end }}
{{- end }}
{{- end -}}

{{- define "cbw.env-config" -}}
- name: {{ .env }}
  valueFrom:
    configMapKeyRef:
      key: {{ .key }}
      name: cbw-config
{{- end -}}

{{- define "cbw.nodeName" -}}
- name: CBW_NODE_NAME
{{- if .Values.node.name }}
  value: {{ .Values.node.name | quote }}
{{- else }}
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
{{- end }}
{{- end -}}

{{- define "cbw.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  namespace: {{ .root.Release.Namespace }}
spec:
  selector:
    app: {{ .name }}
  clusterIP: None
{{- end -}}

{{- define "cbw.image" -}}
- image: {{ .image.registry | default .global.image.registry }}/{{ .image.repository }}:{{ .image.tag | default .global.image.tag }}
  imagePullPolicy: {{ .image.pullPolicy | default .global.image.pullPolicy }}
{{- end -}}

{{- define "cbw.imagePullSecrets" -}}
imagePullSecrets:
{{- range .image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- range .global.image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end -}}

{{- define "cbw.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{- define "cbw.sameNodeAsPod" -}}
affinity:
  podAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - {{ .name }}
      topologyKey: kubernetes.io/hostname
{{- end -}}

# To determine if the machine is online, previous version checked whether 'image.pullPolicy' is equal to 'Never', but
# the user may want no to pull the image while beeing online. Let's use key '.Values.node.offline' if explicitely set,
# and default to using 'image.pullPolicy'.
{{- define "cbw.isOffline" -}}
{{- if or (default false .Values.node.offline) (eq .Values.global.image.pullPolicy "Never") -}}
"true"
{{- end -}}
{{- end -}}

# {{ include (print $.Template "/" .file) . | sha256sum }}
{{- define "cbw.fileCheckSum" -}}
checksum/{{ .file }}: {{ include (print .context.Template.BasePath "/" .file) .context | sha256sum }}
{{- end -}}

{{- define "imagePullSecret" }}
{{- $username := ternary (printf "%s%s" "cbw$" .username) .username (and (eq .registry "harbor.cyberwatch.fr/cbw-on-premise") (not (hasPrefix "cbw$" .username))) -}}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry $username .password .email (printf "%s:%s" $username .password | b64enc) | b64enc }}
{{- end }}

# To determine if the root certificate autorithy (root-ca) of the database should be mounted in the pod.
# Should be used with external database.
{{- define "mountDabaseTLSSecret" -}}
{{- if .Values.database.external -}}
{{- if and .Values.database.tls.mode (ne .Values.database.tls.mode "disabled") -}}
true
{{- end -}}
{{- end -}}
{{- end -}}

# Used to check if deployment/statefulset is in HPA target list.
{{- define "autoscalingEnabledFor" -}}
{{- $name := .name }}
{{- $targets := .targets }}
{{- $found := false }}
{{- range $targets }}
  {{- if eq .name $name }}
    {{- $found = true }}
  {{- end }}
{{- end }}
{{- if $found }}true{{ else }}false{{ end }}
{{- end }}

{{- define "cbw.api-url" -}}
{{- $apiKey := "" -}}
{{- if .KeyString -}}
  {{- $apiKey = .KeyString -}}
{{- else if and .secretRef .secretRef.name .secretRef.key -}}
  {{- $secretName := .secretRef.name -}}
  {{- $secretKey := .secretRef.key -}}
  {{- $secret := (lookup "v1" "Secret" .context.Release.Namespace $secretName) -}}
  {{- if and $secret $secret.data (index $secret.data $secretKey) -}}
    {{- $apiKey = index $secret.data $secretKey | b64dec -}}
  {{- end -}}
{{- end -}}
{{- if $apiKey -}}
- name: API_URL
  value: "https://{{ $apiKey }}@nginx"
- name: SSL_VERIFY
  value: "0"
{{- end -}}
{{- end -}}
