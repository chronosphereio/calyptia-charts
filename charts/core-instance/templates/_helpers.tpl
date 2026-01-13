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
Return the imagePullSecrets for the core-instance deployment.
Uses global.imagePullSecrets which applies to all images (fromCloud, toCloud, etc.).
*/}}
{{- define "instance.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.images.fromCloud .Values.images.toCloud) "global" .Values.global) }}
{{- end -}}

{{- define "createImagePullSecret" -}}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end -}}
{{- end -}}

{{/*
Support httpProxy and backwards-compatible http_proxy
*/}}
{{- define "instance.httpProxy" -}}
  {{- if not (empty .Values.http_proxy) -}}
    {{- printf "%s" .Values.http_proxy -}}
  {{- else -}}
    {{ default "" .Values.httpProxy }}
  {{- end -}}
{{- end -}}

{{- define "instance.httpsProxy" -}}
  {{- if not (empty .Values.https_proxy) -}}
    {{- printf "%s" .Values.https_proxy -}}
  {{- else -}}
    {{ default "" .Values.httpsProxy }}
  {{- end -}}
{{- end -}}

{{- define "instance.noProxy" -}}
  {{- if not (empty .Values.no_proxy) -}}
    {{- printf "%s" .Values.no_proxy -}}
  {{- else -}}
    {{ default "" .Values.noProxy }}
  {{- end -}}
{{- end -}}

{{- define "instance.cloudProxy" -}}
  {{- if not (empty .Values.cloud_proxy) -}}
    {{- printf "%s" .Values.cloud_proxy -}}
  {{- else -}}
    {{ default "" .Values.cloudProxy }}
  {{- end -}}
{{- end -}}
