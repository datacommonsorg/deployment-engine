# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

{{/*
Expand the name of the chart.
*/}}
{{- define "datacommons.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "datacommons.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "datacommons.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "datacommons.labels" -}}
helm.sh/chart: {{ include "datacommons.chart" . }}
{{ include "datacommons.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: datacommons
{{- end }}

{{/*
Selector labels
*/}}
{{- define "datacommons.selectorLabels" -}}
app.kubernetes.io/name: {{ include "datacommons.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: datacommons
{{- end }}

{{/*
Service Account name
*/}}
{{- define "datacommons.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default "datacommons-ksa" .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
GCS output directory
*/}}
{{- define "datacommons.gcsOutputDir" -}}
{{- $bucket := .Values.config.gcs.bucket }}
{{- $prefix := .Values.config.gcs.pathPrefix }}
{{- if $prefix }}
{{- printf "%s/%s/output" $bucket $prefix }}
{{- else }}
{{- printf "%s/output" $bucket }}
{{- end }}
{{- end }}

{{/*
GCS input directory
*/}}
{{- define "datacommons.gcsInputDir" -}}
{{- $bucket := .Values.config.gcs.bucket }}
{{- $prefix := .Values.config.gcs.pathPrefix }}
{{- if $prefix }}
{{- printf "%s/%s/input" $bucket $prefix }}
{{- else }}
{{- printf "%s/input" $bucket }}
{{- end }}
{{- end }}

{{/*
Namespace for resources
*/}}
{{- define "datacommons.namespace" -}}
{{- .Release.Namespace }}
{{- end }}
