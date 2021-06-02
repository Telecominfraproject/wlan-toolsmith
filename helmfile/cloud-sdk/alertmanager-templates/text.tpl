{{ range .Alerts -}}
*Alert:* {{ .Annotations.title }}

*Description:* {{ .Annotations.description }}

*Details:*
  {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
  {{ end }}
{{ end }}