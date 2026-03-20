# Data Commons Accelerator - Terraform Infrastructure

This Terraform configuration deploys Data Commons Accelerator to Google Kubernetes Engine (GKE) with CloudSQL MySQL and Cloud Storage backends. It manages Private Service Access for database connectivity, Workload Identity for secure GCP service integration, and deploys the application via Helm.

## Enterprise Flexibility Features

This solution is designed for enterprise environments with maximum flexibility:

### Resource Naming with Random Suffixes

By default, resources use auto-generated names with random suffixes to prevent collisions:
- CloudSQL instance: `{deployment-name}-db-{random-suffix}`
- GCS bucket: `{deployment-name}-data-{random-suffix}`
- Service account: `{deployment-name}-sa-{random-suffix}`

### Name Overrides (Optional)

For environments requiring specific resource names (compliance, naming conventions):
- `cloudsql_instance_name_override` - Specify exact CloudSQL instance name
- `gcs_bucket_name_override` - Specify exact GCS bucket name
- `service_account_name_override` - Specify exact service account name

### Pre-existing Resources Support

- **Namespace**: Set `create_namespace = false` if namespace already exists
- **APIs**: Handles pre-enabled APIs idempotently (no errors if already enabled)

### Example: Enterprise Deployment with Existing Resources

```hcl
# Use existing namespace
create_namespace          = false
namespace                 = "datacommons-prod"

# Override resource names to match enterprise conventions
cloudsql_instance_name_override   = "dc-mysql-prod-001"
gcs_bucket_name_override          = "company-dc-data-prod"
service_account_name_override     = "svc-datacommons-prod"
```

## Requirements

- GCP project with required APIs enabled
- Existing GKE cluster (VPC-native, Workload Identity enabled) — only required when deploying to an existing cluster
- Terraform >= 1.5.7
- Google Cloud Provider >= 7.0.0
- Kubernetes Provider >= 2.20
- Helm Provider >= 2.12

### Deployment Service Account IAM Roles

The deployment service account (created by GCP Marketplace and used by Infrastructure Manager to run Terraform) must have the following IAM roles assigned at the project level:

| Role | Purpose |
|------|---------|
| `roles/container.developer` | Deploy to GKE cluster (Helm releases, namespaces, secrets) |
| `roles/cloudsql.admin` | Create and manage CloudSQL MySQL instances |
| `roles/storage.admin` | Create and manage GCS buckets |
| `roles/iam.serviceAccountAdmin` | Create and manage GCP service accounts (Workload Identity) |
| `roles/compute.networkAdmin` | Manage VPC networking and Private Service Access |
| `roles/serviceusage.serviceUsageAdmin` | Enable required GCP APIs |
| `roles/serviceusage.apiKeysAdmin` | Create Google Maps API keys |
| `roles/resourcemanager.projectIamAdmin` | Assign IAM roles to service accounts at project level |

These roles are configured in the GCP Marketplace Producer Portal during solution setup. Additionally, the **Infrastructure Manager Agent** service account requires `roles/resourcemanager.projectIamAdmin` to function.

## What Gets Deployed

- CloudSQL MySQL instance with private IP
- Cloud Storage bucket for data artifacts
- Workload Identity binding (GKE service account ↔ GCP service account)
- Google Maps API keys (if needed)
- Kubernetes secrets for database credentials
- Helm release of Data Commons application

## Private Service Access

CloudSQL uses private IP connectivity via Private Service Access (PSA). A /20 IP range is automatically allocated and a PSA connection is created during deployment. If the VPC already has PSA configured, the existing ranges are preserved alongside the new one.

## Configuration

### Terraform Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.7 |
| google | >= 7.0.0, < 8.0.0 |
| google-beta | >= 7.0.0, < 8.0.0 |
| helm | ~> 2.12.0 |
| kubernetes | >= 2.20.0 |
| random | ~> 3.6.0 |

### Providers

| Name | Version |
|------|---------|
| google | 7.15.0 |
| helm | 2.12.1 |
| kubernetes | 3.0.1 |
| random | 3.6.3 |

### Modules

| Name | Source |
|------|--------|
| cloudsql | ./modules/cloudsql |
| gcs_bucket | ./modules/gcs-bucket |
| k8s_secrets | ./modules/k8s-secrets |
| maps_api_keys | ./modules/maps-api-keys |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| goog_cm_deployment_name | Deployment name for the Data Commons Accelerator solution (used by GCP Marketplace for tracking and avoiding resource name collisions) | string | n/a | yes |
| project_id | GCP project ID where Data Commons Accelerator will be deployed | string | n/a | yes |
| create_new_cluster | Create a new GKE cluster with VPC networking (VPC, subnet, Cloud Router, Cloud NAT, and PSA). When false, deploy to an existing cluster specified by gke_cluster_name. | bool | `true` | no |
| region | GCP region for the new GKE cluster and networking resources. Only used when create_new_cluster is true. | string | `"us-central1"` | no |
| gke_cluster_name | Name of the existing GKE cluster to deploy to. Only used when create_new_cluster is false. | string | `""` | no |
| gke_cluster_location | Location (region or zone) of the existing GKE cluster. The GCP region for CloudSQL and other resources is derived from this value. Only used when create_new_cluster is false. | string | `""` | no |
| namespace | Kubernetes namespace for Data Commons Accelerator deployment. Defaults to the deployment name if not provided. | string | `""` | no |
| create_namespace | Create new Kubernetes namespace. Set to false if namespace already exists. | bool | `true` | no |
| cloudsql_instance_name_override | Override CloudSQL instance name (uses generated name if not specified) | string | `""` | no |
| gcs_bucket_name_override | Override GCS bucket name (uses generated name if not specified) | string | `""` | no |
| service_account_name_override | Override service account name (uses generated name if not specified) | string | `""` | no |
| cdc_services_image_repo | Container image repository for CDC Services (populated by GCP Marketplace) | string | n/a | yes |
| cdc_services_image_tag | Container image tag for CDC Services (populated by GCP Marketplace) | string | n/a | yes |
| data_image_repo | Container image repository for Data service (populated by GCP Marketplace) | string | n/a | yes |
| data_image_tag | Container image tag for Data service (populated by GCP Marketplace) | string | n/a | yes |
| helm_chart_repo | Helm chart repository URL (populated by GCP Marketplace) | string | n/a | yes |
| helm_chart_version | Helm chart version (populated by GCP Marketplace) | string | n/a | yes |
| helm_chart_name | Helm chart name (populated by GCP Marketplace) | string | `"datacommons"` | no |
| app_replicas | Number of replicas for the Data Commons Accelerator application deployment | number | `1` | no |
| resource_tier | Resource allocation tier for the application (small, medium, large). Also controls CloudSQL machine tier and high availability. | string | `"medium"` | no |
| flask_env | Data Commons sample (health, education, energy, custom) | string | `"health"` | no |
| dc_api_key | Data Commons API key for accessing Data Commons APIs | string | n/a | yes |
| enable_natural_language | Enable natural language query features | bool | `true` | no |
| enable_data_sync | Enable automatic synchronization of custom data from GCS bucket to CloudSQL database | bool | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Kubernetes namespace where DataCommons is deployed |
| gcs\_bucket\_url | GCS bucket URL (gs://\<bucket\_name\>) |
| kubectl\_configure | Command to configure kubectl for your GKE cluster |
| verify\_pods | Command to verify Data Commons pods are running |
| port\_forward | Port-forward command to access Data Commons locally (with auto-retry) |
| cloud\_shell\_access | Cloud Shell quick access instructions for Data Commons |
| upload\_data | Command to upload custom data to GCS bucket |
| view\_logs | Command to view application logs |
| retrieve\_admin\_credentials | Commands to retrieve admin panel credentials (username and password) |
