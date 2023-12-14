{{- define "hotReload.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.images.hotReload "global" .Values.global) }}
{{- end -}}

{{- define "fluentBit.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.images.fluentBit "global" .Values.global) }}
{{- end -}}

{{- define "ingestCheck.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.images.ingestCheck "global" .Values.global) }}
{{- end -}}

{{- define "validateServiceType" -}}
{{- $validTypes := list "NodePort" "LoadBalancer" "ClusterIP" -}}
{{- $type := .Values.pipelineServiceType | default "LoadBalancer" -}}
{{- if has $type $validTypes -}}
{{- $type  -}}
{{- else -}}
LoadBalancer
{{- end -}}
{{- end -}}