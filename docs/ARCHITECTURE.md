# A10 Corp Azure Infrastructure - Architecture

**Last Updated**: 2025-12-20
**Scope**: Enterprise Landing Zone (Platform Foundation)
**Terraform**: >= 1.0 | **Azure Provider**: ~> 4.0

---

## Overview

This repository manages the **Platform Landing Zone** for A10 Corp. It follows a three-module architecture based on the Azure Cloud Adoption Framework (CAF), providing a secure, governed, and monitored "Virtual Data Center" for application teams to consume.

### Core Tiers

1. **Common** (`modules/common`): Shared library for naming logic, variable defaults, and global data sources.
2. **Foundation** (`foundation/`): Global organizational resources (Management Groups, Subscription Associations, Global ACR, Central Log Analytics).
3. **Workloads** (`workloads/`): Environment-specific networking and identity (Resource Groups, VNets, Subnets, NSGs, Managed Identities).

---

## Architecture Design

### 1. Governance & Guardrails
Governance is enforced via **Native Terraform Policies** assigned at the `mg-a10corp-hq` level.
- **Tagging**: Required `Environment` tag on Resource Groups.
- **Location**: Restricted to `eastus` (primary) and `eastus2` (failover).
- **Cost**: Restricted VM SKUs (B and D series).
- **Security**: Mandatory Secure Transfer (HTTPS) for Storage Accounts.

### 2. Observability (Persistent Forensics)
All platform logs are centralized in a **Permanent Log Analytics Workspace** (`log-a10corp-hq`) located in the root management subscription.
- **Persistence**: Logs outlive the workload environments.
- **Coverage**: VNet metrics and NSG flow logs (Events/Rules) are automatically shipped to this workspace.

### 3. Resilience & Disaster Recovery
A **Permanent Backup Storage Account** (`sta10corpsales`) is provisioned in the Foundation layer.
- **Purpose**: Long-term retention of application backups (JSON submissions).
- **Configuration**: Standard_LRS, Cool tier (mirrors `storerootblob` for consistency).
- **Structure**: Dedicated containers for each environment (`backups-dev`, `backups-stage`, `backups-prod`).
- **Access**: RBAC-based with `Storage Blob Data Contributor` granted to AKS managed identities. Network rules allow all traffic with Azure Services bypass.

### 4. Networking (The "Roads")
The platform provides a **Network-Vended** model. Application teams are expected to deploy their compute (AKS, VMs) into the provided subnets:
- `snet-*-aks-nodes`: Protected by NSG (Allow HTTP/80, AzureLB), intended for private compute nodes.
- `snet-*-ingress`: Protected by NSG (Allow HTTP/HTTPS), intended for Load Balancers/Ingress.
- **Routing**: Each environment includes a Route Table with a default 0.0.0.0/0 Internet route.

### 4. Identity (Workload Identity Federation)
Managed Identities (`id-a10corp-sales-{env}`) are pre-provisioned and granted:
- `AcrPull` on the Global ACR (for image pulling).
- `Network Contributor` on the environment VNet (for node management).

---

## Deployment Status

| Component | Status | Env | Highlights |
|-----------|--------|-----|------------|
| **Foundation** | ✅ Active | Global | MGs, Policy, ACR, Central LAW |
| **Workloads** | ✅ Active | Dev | RG, VNet, NSG, UDR, Identity |
| **Workloads** | ✅ Active | Stage | RG, VNet, NSG, UDR, Identity |
| **Workloads** | ✅ Active | Prod | RG, VNet, NSG, UDR, Identity |

---

## CI/CD Strategy

GitHub Actions with OIDC authentication and security-first principles:
- **Trivy Scanning**: Every plan is scanned for IaC misconfigurations (Shift-Left Security).
- **Automated Planning**: Plans run on every Push/PR to `main`.
- **Gated Applies**: Deployments to `global`, `dev`, `stage`, and `prod` environments require manual approval.
- **Audit Trail**: All human-readable plans are archived in Azure Blob Storage.

---

## Reference Links

- **Decision Records**: [DECISIONS.md](DECISIONS.md)
- **Roadmap**: [NEXTSTEPS.md](NEXTSTEPS.md)
- **User Manual**: [USER_MANUAL.md](USER_MANUAL.md)