# GCP Marketplace Deployment Form Fields Reference

---

## Form Overview

The deployment form has **5 fields** across **2 sections**. A new GKE cluster is created automatically in your selected region.

---

## Deployment Name

| Field | Default | Description |
|-------|---------|-------------|
| **Deployment Name** | — | A unique name for this deployment (2-18 characters). Used to generate resource names for the cluster, database, and storage. |

---

## GCP Region

| Field | Default | Description |
|-------|---------|-------------|
| **GCP Region** | us-central1 | The GCP region where the cluster and all cloud resources will be created. |

---

## Section 0: Application Settings

| Field | Default | Description |
|-------|---------|-------------|
| **Resource Tier** | Medium | Controls how much CPU and memory the application gets, and the size of the database |
| **Domain Template** | Health | Pre-built configuration optimized for your domain |

### Resource Tier

| Option | Memory | CPU | Replicas | Database size | High availability |
|--------|--------|-----|----------|---------------|-------------------|
| Small | 2 GB | 1 core | 1 | Standard | No |
| Medium (recommended) | 4 GB | 2 cores | 2 | Standard | No |
| Large | 8 GB | 4 cores | 3 | Large | Yes |

### Domain Template

| Option | Best for |
|--------|----------|
| Health | Health and epidemiology data |
| Education | School, enrollment, and outcomes data |
| Energy | Energy consumption and generation data |

You can customize the template after deployment.

---

## Section 1: API Keys

| Field | Default | Description |
|-------|---------|-------------|
| **Data Commons API Key** | — | Required for the application to access Data Commons data. Get yours at [docs.datacommons.org](https://docs.datacommons.org/custom_dc/quickstart.html#get-a-data-commons-api-key). |
