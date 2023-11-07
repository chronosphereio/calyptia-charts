{{/*
Returns the proper service account name depending if an explicit service account name is set
in the values file. If the name is not set it will default to either common.names.fullname if serviceAccount.create
is true or default otherwise.
*/}}
{{- define "instance.serviceAccountName" -}}
    {{- if .Values.serviceAccount.create -}}
        {{- if (empty .Values.serviceAccount.name) -}}
          {{- printf "calyptia-core-instance-%s-sa" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
        {{- else -}}
          {{ default "default" .Values.serviceAccount.name }}
        {{- end -}}
    {{- else -}}
        {{ default "default" .Values.serviceAccount.name }}
    {{- end -}}
{{- end -}}

{{/*
Return the proper fromCloud.image image name
*/}}
{{- define "fromCloud.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.images.fromCloud "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper toCloud.image image name
*/}}
{{- define "toCloud.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.images.toCloud "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper hotReload.image image name
*/}}
{{- define "hotReload.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.images.hotReload "global" .Values.global) }}
{{- end -}}

{{- define "ingestCheck.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.images.ingestCheck "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "fromCloud.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.images.fromCloud) "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "toCloud.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.images.toCloud) "global" .Values.global) }}
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
