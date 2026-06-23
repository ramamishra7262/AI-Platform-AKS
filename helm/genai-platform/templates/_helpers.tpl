{{- define "genai.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "genai.fullname" -}}
{{- printf "%s-%s" (include "genai.name" .) .Values.global.environment | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "genai.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
environment: {{ .Values.global.environment }}
{{- end }}

{{- define "genai.image" -}}
{{- $registry := .Values.global.registry -}}
{{- $image := .image -}}
{{- $tag := .tag | default "latest" -}}
{{- if $registry }}{{ $registry }}/{{ $image }}:{{ $tag }}{{ else }}{{ $image }}:{{ $tag }}{{ end }}
{{- end }}
