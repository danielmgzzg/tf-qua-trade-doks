{{- define "freqtrade-bot.name" -}}
freqtrade-bot
{{- end -}}
{{- define "freqtrade-bot.fullname" -}}
{{ include "freqtrade-bot.name" . }}-{{ .Release.Name }}
{{- end -}}
