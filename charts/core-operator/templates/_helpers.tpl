{{/*
Returns the proper service account name depending if an explicit service account name is set
in the values file. If the name is not set it will default to either common.names.fullname if serviceAccount.create
is true or default otherwise.
*/}}
{{- define "operator.serviceAccountName" -}}
    {{- if .Values.serviceAccount.create -}}
        {{- if (empty .Values.serviceAccount.name) -}}
          {{- printf "%s-calyptia-core-operator" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
        {{- else -}}
          {{ default "default" .Values.serviceAccount.name }}
        {{- end -}}
    {{- else -}}
        {{ default "default" .Values.serviceAccount.name }}
    {{- end -}}
{{- end -}}

{{/*
Return the proper operator.image image name
*/}}
{{- define "operator.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.images.operator "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper hotReload.image image name
*/}}
{{- define "hotReload.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.images.hotReload "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "operator.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.images.operator) "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "hotReload.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.images.hotReload) "global" .Values.global) }}
{{- end -}}

{{- define "createImagePullSecret" -}}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end -}}
{{- end -}}
