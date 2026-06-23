# Deployment Guide - Enterprise GenAI Platform

## Environment Promotion Flow

```
Feature Branch → PR → dev → QA → prod
     ↓              ↓      ↓      ↓
  Terraform      ArgoCD  Manual  ArgoCD
   plan PR        Sync  Approval  Sync
```

## Pipeline Variables Reference

### GitHub Secrets
| Secret | Description |
|--------|-------------|
| AZURE_CLIENT_ID | OIDC Service Principal Client ID |
| AZURE_TENANT_ID | Azure Tenant ID |
| AZURE_SUBSCRIPTION_ID | Azure Subscription ID |
| TF_BACKEND_RG | Terraform state resource group |
| TF_BACKEND_SA | Terraform state storage account |

### Azure DevOps Variable Groups (`genai-platform-secrets`)
| Variable | Description |
|----------|-------------|
| AZURE_SERVICE_CONNECTION | Azure DevOps service connection name |
| ACR_NAME | Container Registry name (without .azurecr.io) |
| AKS_CLUSTER_NAME | AKS cluster resource name |
| RESOURCE_GROUP | AKS resource group |
| KEYVAULT_NAME | Key Vault resource name |
| OPENAI_ENDPOINT | Azure OpenAI endpoint URL |
| SEARCH_ENDPOINT | Azure AI Search endpoint URL |
| API_URL | Backend API URL for frontend VITE_API_URL |

## ArgoCD Setup

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward to ArgoCD UI
kubectl -n argocd port-forward svc/argocd-server 8080:443

# Login
argocd login localhost:8080 --username admin --insecure

# Add git repo
argocd repo add https://github.com/ramamishra7262/AI-Platform-AKS.git \
  --username ramamishra7262 --password <PAT>

# Bootstrap
kubectl apply -f k8s/argocd/root-app.yaml
```

## Rollback Procedures

### Application Rollback (ArgoCD)
```bash
# Rollback to previous revision
argocd app rollback genai-platform <REVISION>
```

### Helm Rollback
```bash
helm rollback genai-platform 1 --namespace genai
```

### Terraform Rollback
```bash
# Revert to previous state version in Azure Storage
# Then re-apply the previous tfvars
terraform apply -var-file="environments/prod/terraform.tfvars"
```
