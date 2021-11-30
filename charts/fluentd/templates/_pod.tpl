{{- define "fluentd.pod" -}}
{{- $defaultTag := printf "%s-debian-elasticsearch7-1.0" (.Chart.AppVersion) -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName }}
{{- end }}
serviceAccountName: {{ include "fluentd.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
containers:
  - name: {{ .Chart.Name }}
    securityContext:
      {{- toYaml .Values.securityContext | nindent 6 }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default $defaultTag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    resources:
      {{- toYaml .Values.resources | nindent 8 }}
    env:
      {{- range .Values.env.config }}
      - name: {{ .name }}
        value: {{ .value }}
      {{- end }}
    volumeMounts:
      {{- toYaml .Values.volumeMounts | nindent 6 }}
      {{- range $key := .Values.configMapConfigs }}
      {{- print "- name: fluentd-custom-cm-" $key  | nindent 6 }}
      {{- print "mountPath: /etc/fluent/" $key ".d"  | nindent 8 }}
      {{- end }}
volumes:
  {{- toYaml .Values.volumes | nindent 2 }}
  {{- range $key := .Values.configMapConfigs }}
  {{- print "- name: fluentd-custom-cm-" $key  | nindent 2 }}
  configMap:
    {{- print "name: " .  | nindent 6 }}
    defaultMode: 0777
    {{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}