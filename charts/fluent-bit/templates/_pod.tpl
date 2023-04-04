{{- define "calyptia-fluent-bit.pod" -}}
serviceAccountName: {{ include "calyptia-fluent-bit.serviceAccountName" . }}
hostNetwork: {{ .Values.hostNetwork }}
dnsPolicy: {{ .Values.dnsPolicy }}
{{- with .Values.dnsConfig }}
dnsConfig:
  {{- toYaml . | nindent 2 }}
{{- end }}

{{- with .Values.initContainers }}
initContainers:
{{- if kindIs "string" . }}
  {{- tpl . $ | nindent 2 }}
{{- else }}
  {{-  toYaml . | nindent 2 }}
{{- end -}}
{{- end }}
containers:
  - name: {{ .Chart.Name }}
  {{- with .Values.securityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
  {{- end }}
    image: "{{ .Values.image.repository }}:{{ default .Chart.AppVersion .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
  {{- if or .Values.env .Values.envWithTpl }}
    env:
    {{- with .Values.env }}
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- range $item := .Values.envWithTpl }}
      - name: {{ $item.name }}
        value: {{ tpl $item.value $ | quote }}
    {{- end }}
  {{- end }}
  {{- if .Values.envFrom }}
    envFrom:
      {{- toYaml .Values.envFrom | nindent 6 }}
  {{- end }}
  {{- if .Values.args }}
    args:
    {{- toYaml .Values.args | nindent 6 }}
  {{- end}}
  {{- if .Values.command }}
    command:
    {{- toYaml .Values.command | nindent 6 }}
  {{- end }}
    ports:
      - name: http
        containerPort: {{ .Values.metricsPort }}
        protocol: TCP
    {{- if .Values.extraPorts }}
      {{- range .Values.extraPorts }}
      - name: {{ .name }}
        containerPort: {{ .containerPort }}
        protocol: {{ .protocol }}
      {{- end }}
    {{- end }}
  {{- with .Values.lifecycle }}
    lifecycle:
      {{- toYaml . | nindent 6 }}
  {{- end }}
    livenessProbe:
      {{- toYaml .Values.livenessProbe | nindent 6 }}
    readinessProbe:
      {{- toYaml .Values.readinessProbe | nindent 6 }}
  {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
  {{- end }}
    volumeMounts:
      {{- toYaml .Values.volumeMounts | nindent 6 }}
    {{- range $key, $val := .Values.config.extraFiles }}
      - name: config
        mountPath: /calyptia-fluent-bit/etc/{{ $key }}
        subPath: {{ $key }}
    {{- end }}
    {{- range $key, $value := .Values.luaScripts }}
      - name: luascripts
        mountPath: /calyptia-fluent-bit/scripts/{{ $key }}
        subPath: {{ $key }}
    {{- end }}
      {{- toYaml .Values.daemonSetVolumeMounts | nindent 6 }}
    {{- if .Values.extraVolumeMounts }}
      {{- toYaml .Values.extraVolumeMounts | nindent 6 }}
    {{- end }}
  {{- if .Values.extraContainers }}
    {{- toYaml .Values.extraContainers | nindent 2 }}
  {{- end }}
volumes:
  - name: config
    configMap:
      name: {{ if .Values.existingConfigMap }}{{ .Values.existingConfigMap }}{{- else }}{{ include "calyptia-fluent-bit.fullname" . }}{{- end }}
{{- if gt (len .Values.luaScripts) 0 }}
  - name: luascripts
    configMap:
      name: {{ include "calyptia-fluent-bit.fullname" . }}-luascripts
{{- end }}
  {{- toYaml .Values.daemonSetVolumes | nindent 2 }}
{{- if .Values.extraVolumes }}
  {{- toYaml .Values.extraVolumes | nindent 2 }}
{{- end }}
{{- end -}}
