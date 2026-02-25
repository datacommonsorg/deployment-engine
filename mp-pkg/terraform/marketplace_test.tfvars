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

# The marketplace_test.tfvars file is used to validate the Terraform template.
# Marketplace will validate your product with this file as its `--var-file`
# argument.
#
# Do not include the following variables in marketplace_test.tfvars, as they
# will be provided by Marketplace:
#
# - project_id
# - helm_chart_repo
# - helm_chart_name
# - helm_chart_version
# - Any variables declared in schema.yaml

goog_cm_deployment_name = "datacommons-test"
create_new_cluster      = true
region                  = "us-central1"
dc_api_key              = "test-api-key-placeholder"
