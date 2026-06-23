# Enterprise GenAI Platform on AKS

A production-grade, enterprise-ready Generative AI platform built on Azure Kubernetes Service (AKS). Enables users to chat with enterprise documents using Retrieval-Augmented Generation (RAG) powered by Azure OpenAI and Azure AI Search.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Azure Subscription                           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    Resource Group                             │   │
│  │                                                               │   │
│  │  ┌─────────┐  ┌─────────────────────────────────────────┐   │   │
│  │  │  Azure   │  │  Private AKS Cluster (Azure CNI Overlay) │   │   │
│  │  │  OpenAI  │  │  ┌──────────┐  ┌────────────────────┐  │   │   │
│  │  │ (GPT-4o) │  │  │  System  │  │    User Node Pool  │  │   │   │
│  │  │ (Embed.) │  │  │  Nodes   │  │  ┌──────────────┐  │  │   │   │
│  │  └────┬─────┘  │  └──────────┘  │  │   genai ns   │  │  │   │   │
│  │       │        │  ┌──────────┐  │  │ ┌──────────┐ │  │  │   │   │
│  │  ┌────┴─────┐  │  │ ArgoCD   │  │  │ │ Backend  │ │  │  │   │   │
│  │  │  Azure   │  │  ├──────────┤  │  │ ├──────────┤ │  │  │   │   │
│  │  │ AI Search│  │  │ Prom/Graf│  │  │ │ RAG Svc  │ │  │  │   │   │
│  │  └────┬─────┘  │  ├──────────┤  │  │ ├──────────┤ │  │  │   │   │
│  │       │        │  │   KEDA   │  │  │ │Ingestion │ │  │  │   │   │
│  │  ┌────┴─────┐  │  ├──────────┤  │  │ ├──────────┤ │  │  │   │   │
│  │  │  Azure   │  │  │  NGINX   │  │  │ │ Frontend │ │  │  │   │   │
│  │  │ Key Vault│  │  │ Ingress  │  │  │ └──────────┘ │  │  │   │   │
│  │  └────┬─────┘  │  └──────────┘  │  └──────────────┘  │  │   │   │
│  │       │        └─────────────────────────────────────────┘  │   │
│  │  ┌────┴─────┐                                                │   │
│  │  │  ACR     │  Private Endpoints for all Azure services      │   │
│  │  │ Storage  │  Private DNS Zones + VNet integration          │   │
│  │  │  VNet    │                                                │   │
│  │  └──────────┘                                                │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## Repository Structure

```
AI-Platform-AKS/
├── terraform/                    # IaC - all Azure resources
│   ├── modules/
│   │   ├── networking/           # VNet, subnets, private DNS zones, NSGs
│   │   ├── aks/                  # Private AKS cluster, node pools, OIDC
│   │   ├── acr/                  # Azure Container Registry + private endpoint
│   │   ├── keyvault/             # Key Vault + RBAC + secret storage
│   │   ├── openai/               # Azure OpenAI (GPT-4o + embeddings)
│   │   ├── ai-search/            # Azure AI Search + private endpoint
│   │   ├── storage/              # ADLS Gen2 for document storage
│   │   ├── monitoring/           # Log Analytics, App Insights, alerts
│   │   ├── managed-identity/     # Workload Identity federated credentials
│   │   └── role-assignments/     # Azure RBAC assignments
│   ├── environments/{dev,qa,prod}/terraform.tfvars
│   └── main.tf, variables.tf, outputs.tf, locals.tf, versions.tf
│
├── apps/
│   ├── backend/                  # FastAPI: auth, chat orchestration (→ RAG svc)
│   ├── rag-service/              # FastAPI: Azure OpenAI + AI Search RAG pipeline
│   ├── ingestion-service/        # FastAPI: PDF upload → chunk → embed → index
│   └── frontend/                 # React: auth, chat UI, document upload
│
├── helm/
│   ├── genai-platform/           # Main Helm chart (all 4 services + ingress + HPA)
│   └── addons/                   # NGINX, cert-manager, external-dns, KEDA, monitoring, secrets-store
│
├── k8s/
│   ├── namespaces/               # Namespace definitions
│   ├── rbac/                     # ServiceAccounts with Workload Identity annotations
│   ├── network-policies/         # Default-deny + allow policies
│   └── argocd/                   # ArgoCD root app + app-of-apps manifests
│
├── gitops/
│   ├── apps/{base,dev,qa,prod}/  # Kustomize overlays for ArgoCD
│   └── infrastructure/           # Infrastructure ArgoCD apps
│
├── azure-devops/
│   └── pipelines/                # terraform-plan, terraform-apply, docker-build-push, helm-deploy
│
├── .github/workflows/            # GitHub Actions alternatives (CI, Terraform, Deploy)
│
└── docs/                         # Architecture docs, runbooks
```

## Services

| Service | Port | Technology | Purpose |
|---------|------|------------|---------|
| Backend | 8000 | FastAPI | Auth (JWT), chat history, request routing → RAG |
| RAG Service | 8001 | FastAPI | Azure AI Search query + GPT-4o response generation |
| Ingestion Service | 8002 | FastAPI | PDF extraction, chunking, embedding, AI Search indexing |
| Frontend | 80 | React + Nginx | Chat UI, document upload, auth pages |

## Azure Resources Deployed

| Resource | Purpose |
|----------|---------|
| Private AKS (Azure CNI Overlay + Cilium) | Container orchestration |
| Azure OpenAI (GPT-4o + text-embedding-3-large) | LLM inference + vector embeddings |
| Azure AI Search (Standard SKU) | Vector + hybrid semantic search (RAG index) |
| Azure Container Registry (Premium) | Container images |
| Azure Key Vault (Premium + HSM) | Secrets, CSI driver integration |
| ADLS Gen2 Storage Account | Document storage |
| Log Analytics + Application Insights | Observability |
| User Assigned Managed Identities | Workload Identity per service |
| Private Endpoints | All services on private network |

## Kubernetes Add-ons

| Add-on | Purpose |
|--------|---------|
| NGINX Ingress Controller | L7 routing, TLS termination |
| cert-manager | Automatic TLS certs via Let's Encrypt |
| ExternalDNS | Azure DNS record management |
| ArgoCD | GitOps continuous deployment |
| Prometheus + Grafana | Metrics, dashboards |
| Loki | Log aggregation |
| KEDA | Event-driven autoscaling (blob storage trigger) |
| Secrets Store CSI Driver | Key Vault → Kubernetes secrets |

## Deployment Guide

### Prerequisites

```bash
az --version          # Azure CLI >= 2.60
terraform --version   # >= 1.6
kubectl version       # >= 1.28
helm version          # >= 3.15
```

### 1. Bootstrap Terraform Remote State

```bash
# Create storage for Terraform state
az group create --name genai-tfstate-rg --location eastus
az storage account create --name genaitfstate --resource-group genai-tfstate-rg \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2
az storage container create --name tfstate --account-name genaitfstate
```

### 2. Deploy Infrastructure

```bash
cd terraform
terraform init \
  -backend-config="resource_group_name=genai-tfstate-rg" \
  -backend-config="storage_account_name=genaitfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=dev/terraform.tfstate"

terraform plan -var-file="environments/dev/terraform.tfvars" -out=dev.tfplan
terraform apply dev.tfplan
```

### 3. Connect to AKS

```bash
AKS_NAME=$(terraform output -raw aks_cluster_name)
RG=$(terraform output -raw resource_group_name)
az aks get-credentials --resource-group $RG --name $AKS_NAME
```

### 4. Install Add-ons

```bash
# NGINX Ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace -f helm/addons/ingress-nginx/values.yaml

# cert-manager
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace -f helm/addons/cert-manager/values.yaml

# ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Kube Prometheus Stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace -f helm/addons/monitoring/values.yaml

# KEDA
helm repo add kedacore https://kedacore.github.io/charts
helm upgrade --install keda kedacore/keda --namespace keda --create-namespace

# Secrets Store CSI Driver
helm repo add csi-secrets-store-provider-azure \
  https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm upgrade --install csi-secrets-store-provider-azure \
  csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --namespace kube-system
```

### 5. Deploy via ArgoCD GitOps

```bash
# Bootstrap ArgoCD root app
kubectl apply -f k8s/argocd/root-app.yaml

# Sync all apps
argocd app sync root-app --prune
```

### 6. Deploy directly with Helm (dev/testing)

```bash
ACR=$(terraform -chdir=terraform output -raw acr_login_server)
OPENAI=$(terraform -chdir=terraform output -raw openai_endpoint)
SEARCH=$(terraform -chdir=terraform output -raw search_endpoint)
KV_NAME=$(terraform -chdir=terraform output -raw keyvault_name)

helm upgrade --install genai-platform ./helm/genai-platform \
  --namespace genai --create-namespace \
  --set global.registry=$ACR \
  --set openai.endpoint=$OPENAI \
  --set azureSearch.endpoint=$SEARCH \
  --set keyvault.name=$KV_NAME
```

## Cost Estimation

| Resource | SKU | Est. Monthly (prod) |
|----------|-----|---------------------|
| AKS (3 system D8s_v5 + 3-20 user D16s_v5) | Pay-as-you-go | ~$2,400–$8,000 |
| Azure OpenAI GPT-4o (50K capacity) | S0 | ~$500–$3,000 (usage-based) |
| Azure OpenAI Embeddings | S0 | ~$50–$300 |
| Azure AI Search | Standard2 | ~$500 |
| Azure Container Registry | Premium | ~$250 |
| Azure Key Vault | Premium | ~$50 |
| Storage Account | ZRS | ~$50–$200 |
| Private Endpoints (6×) | - | ~$50 |
| Log Analytics (90-day retention) | PerGB2018 | ~$100–$500 |
| **Total estimate** | | **~$4,000–$13,000/mo** |

*Costs vary by region, actual token usage, and traffic. Dev/QA envs are 60–80% cheaper.*

## Production Hardening Checklist

### Infrastructure
- [x] Private AKS cluster (no public API endpoint)
- [x] Azure CNI Overlay with Cilium network policy
- [x] Private endpoints for all Azure PaaS services
- [x] Private DNS zones for all private endpoints
- [x] Managed Identity / Workload Identity (no secrets in env vars)
- [x] Key Vault with RBAC, soft-delete, purge protection
- [x] ACR with Premium SKU, geo-replication, admin disabled
- [x] Storage: TLS 1.2 min, HNS enabled, no public access
- [ ] Azure Defender for Containers enabled
- [ ] Azure Policy for AKS (restrict privileged containers)
- [ ] NAT Gateway for outbound (no direct internet from nodes)

### Application Security
- [x] Non-root containers, readOnlyRootFilesystem
- [x] Resource limits/requests on all containers
- [x] Network policies: default-deny with explicit allow rules
- [x] Secrets served via Secrets Store CSI (not in K8s Secret objects)
- [x] JWT authentication on all API endpoints
- [ ] API rate limiting (via NGINX `nginx.ingress.kubernetes.io/limit-rps`)
- [ ] Input validation / prompt injection guardrails
- [ ] mTLS between services (via Istio or Azure Service Mesh)
- [ ] SBOM generation in CI (Syft + Grype)

### Observability
- [x] Prometheus metrics scraping all services
- [x] Grafana dashboards for GenAI platform
- [x] Loki log aggregation
- [x] Azure Monitor + Application Insights integration
- [x] Alert rules for CPU, memory, error rates
- [ ] OpenTelemetry distributed tracing (traces to App Insights)
- [ ] SLO/SLA dashboards (Grafana)
- [ ] On-call runbooks in monitoring repo

### Reliability
- [x] HPA on backend, RAG service (CPU-based)
- [x] KEDA on ingestion service (blob trigger)
- [x] PodDisruptionBudgets (add to helm chart)
- [x] Multi-AZ node pools
- [x] AKS cluster auto-upgrade (maintenance window set)
- [ ] Velero for backup/restore
- [ ] Chaos engineering (Azure Chaos Studio)
- [ ] Load testing before production (k6)

### GitOps & CI/CD
- [x] ArgoCD App-of-Apps pattern
- [x] Kustomize overlays per environment
- [x] Trivy vulnerability scanning in CI
- [x] Terraform plan reviewed in PR before apply
- [ ] OPA/Conftest policies for Terraform
- [ ] Image signing with Cosign / Notation
- [ ] Branch protection on main (require PR review)
- [ ] Dependabot for dependency updates

## Azure Well-Architected Framework Alignment

| Pillar | Implementation |
|--------|---------------|
| **Reliability** | Multi-AZ AKS, HPA/KEDA autoscaling, PDB, AKS auto-upgrade |
| **Security** | Private cluster, private endpoints, Workload Identity, Key Vault CSI, Network Policies |
| **Cost Optimization** | KEDA (scale to zero for ingestion), Ephemeral OS disks, right-sized SKUs per env |
| **Operational Excellence** | GitOps (ArgoCD), IaC (Terraform), full CI/CD, structured logging, tracing |
| **Performance Efficiency** | Azure CNI Overlay + Cilium eBPF, GPU node pool ready, AI Search semantic ranking |
