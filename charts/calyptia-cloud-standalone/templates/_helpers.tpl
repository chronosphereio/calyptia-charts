{{/*
Create the name of the service account to use
*/}}
{{- define "calyptia-standalone.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "calyptia-standalone.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper cloud.image image name
*/}}
{{- define "cloud.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.cloudApi.images.cloud "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper frontend.image image name
*/}}
{{- define "frontend.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.frontend.images.frontend "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper vivo.image image name
*/}}
{{- define "vivo.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.vivo.images.vivo "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper cloud.kubectl.image image name
*/}}
{{- define "cloud.kubectl.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.cloudApi.images.kubectl "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper cloud.influxdb.image image name
*/}}
{{- define "cloud.influxdb.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.cloudApi.images.influxdb "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper cloud.postgres.image image name
*/}}
{{- define "cloud.postgres.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.cloudApi.images.postgres "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper frontend.luaSandbox.image image name
*/}}
{{- define "frontend.luaSandbox.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.frontend.images.luaSandbox "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper ingress.image image name
*/}}
{{- define "ingress.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.ingress.images.nginx "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper reloader.image image name
*/}}
{{- define "reloader.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.reloader.images.reloader "global" .Values.global) }}
{{- end -}}

{{/*
Returns the proper service account name depending if an explicit service account name is set
in the values file. If the name is not set it will default to either common.names.fullname if serviceAccount.create
is true or default otherwise.
*/}}
{{- define "cloud.serviceAccountName" -}}
    {{- if .Values.cloudApi.serviceAccount.create -}}
        {{- if (empty .Values.cloudApi.serviceAccount.name) -}}
          {{- printf "%s-cloud" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
        {{- else -}}
          {{ default "default" .Values.cloudApi.serviceAccount.name }}
        {{- end -}}
    {{- else -}}
        {{ default "default" .Values.cloudApi.serviceAccount.name }}
    {{- end -}}
{{- end -}}

{{/*
Returns the proper service account name depending if an explicit service account name is set
in the values file. If the name is not set it will default to either common.names.fullname if serviceAccount.create
is true or default otherwise.
*/}}
{{- define "frontend.serviceAccountName" -}}
    {{- if .Values.frontend.serviceAccount.create -}}
        {{- if (empty .Values.frontend.serviceAccount.name) -}}
          {{- printf "%s-frontend" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
        {{- else -}}
          {{ default "default" .Values.frontend.serviceAccount.name }}
        {{- end -}}
    {{- else -}}
        {{ default "default" .Values.frontend.serviceAccount.name }}
    {{- end -}}
{{- end -}}

{{/*
Returns the proper service account name depending if an explicit service account name is set
in the values file. If the name is not set it will default to either common.names.fullname if serviceAccount.create
is true or default otherwise.
*/}}
{{- define "reloader.serviceAccountName" -}}
    {{- if .Values.reloader.serviceAccount.create -}}
        {{- if (empty .Values.reloader.serviceAccount.name) -}}
          {{- printf "%s-reloader" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
        {{- else -}}
          {{ default "default" .Values.reloader.serviceAccount.name }}
        {{- end -}}
    {{- else -}}
        {{ default "default" .Values.reloader.serviceAccount.name }}
    {{- end -}}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "cloud.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.cloudApi.images.cloud) "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "cloud.postgres.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.cloudApi.images.postgres) "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "cloud.influxdb.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.cloudApi.images.influxdb) "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "frontend.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.frontend.images.frontend) "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "frontend.luaSandbox.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.frontend.images.luaSandbox) "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "vivo.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.vivo.images.vivo) "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Container Registry Secret Names
*/}}
{{- define "reloader.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.reloader.images.reloader) "global" .Values.global) }}
{{- end -}}

{{- define "createImagePullSecret" -}}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end -}}
{{- end -}}
