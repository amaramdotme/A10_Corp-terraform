# Platform Infrastructure Requirements
**Project:** A10 Corp - Sales Fulfillment Application
**Requestor:** Application Team (App Repo)
**Status:** ✅ Implemented (2025-12-20)

## 1. Permanent Assets (Foundation / Root)
*These assets must persist even if the `workloads` module is destroyed.*

### A. Azure Container Registry (ACR)
*   **Name:** `acrsalesshared` (or similar compliant naming).
*   **Role Assignment:** Grant `AcrPull` to the AKS Kubelet identity (if possible at provision time).
*   **Status:** ✅ Implemented

### B. Storage Account (for Application Backups)
*   **Purpose:** Store JSON backups of application submissions for long-term durability.
*   **Containers required:** `backups-dev`, `backups-stage`, `backups-prod`.
*   **Access:** Must allow "Azure Services" to bypass firewall for cross-region access.
*   **Status:** ✅ Implemented (`sta10corpsales`)

### C. Governance & Policy
*   **Allowed Locations:** Update policy to allow `eastus2` (failover for saturated `eastus` services like SQL/Compute).
*   **Status:** ✅ Implemented

---

## 2. Ephemeral Assets (Workloads Module)
*These assets are created/destroyed with the Environment lifecycle.*

### A. Networking (VNet & NSG)
*   **Subnet:** `snet-aks-nodes`.
*   **NSG Rules (REQUIRED):**
    1.  **AllowHttpInbound:** Allow `Internet` on port `80` (mapped to AKS Load Balancer).
    2.  **AllowAzureLBInbound:** Allow all traffic from `AzureLoadBalancer` service tag (for health probes).
*   **Status:** ✅ Implemented

### B. Managed Identity
*   **Role Assignments:**
    *   **`Storage Blob Data Contributor`** on the Permanent Storage Account (so AKS nodes can write backups).
    *   **`User Access Administrator`** on the **Permanent ACR and Storage Account** for the **OIDC Service Principal** (so this App Repo can manage its own RBAC assignments via Terraform).
*   **Status:** ✅ Implemented (Storage Contributor granted; User Access Admin skipped as OIDC SP has Owner)

---

## 3. Outputs Required (from Workloads or Foundation)
*   `resource_group_name`
*   `vnet_id`
*   `subnet_id_aks_nodes`
*   `identity_id_aks` (Resource ID)
*   `storage_account_id` (Resource ID of the permanent storage account)
*   `storage_account_name` (Name of the permanent storage account)
*   **Status:** ✅ Implemented
