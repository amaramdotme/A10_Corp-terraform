# Platform Infrastructure Requirements
**Project:** A10 Corp - Sales Fulfillment Application
**Requestor:** Application Team (App Repo)

## Background 
Three Tier Infra Stack

   1. Permanent (Root/Foundation): Artifacts that must survive a "nuke" of the environment (Docker Images, Terraform State, Secrets).
   2. Ephemeral (Workloads): The runtime environment (Networking, RGs).
   3. Application (This Repo): The compute (AKS) and data (SQL) that sits on top of the ephemeral workload network.

## Context
The Application Repo (`A10_Corp-Sales_Fulfillment`) requires specific infrastructure components to be provisioned by the Platform/Landing Repo (`A10_Corp-terraform`). The application follows a "Poly-repo" strategy where the Platform manages networking and governance, while the App manages compute (AKS) and data.

## 1. Permanent Assets (Foundation / Root)
*These assets must persist even if the `workloads` module is destroyed.*

### A. Azure Container Registry (ACR)
*   **Name:** `acrsalesshared` (or similar compliant naming).
*   **Location:** Same as `rg-root-iac` or primary region.
*   **SKU:** Basic or Standard.
*   **Reason:** Stores build artifacts (Docker images) for Frontend and Backend. These must not be deleted when the Stage/Prod environments are recycled.

### B. State Management
*   Ensure the existing storage account in `rg-root-iac` allows read access to the `workloads` container so the App Repo can read the `tfstate` to discover VNet/Subnet IDs.

---

## 2. Ephemeral Assets (Workloads Module - Stage)
*These assets are created/destroyed with the Environment lifecycle.*

### A. Resource Group
*   **Name:** `rg-sales-stage-eastus` (follows naming convention).
*   **Tags:** `Environment=Stage`, `Workload=SalesFulfillment`.

### B. Networking (VNet)
*   **Name:** `vnet-sales-stage-eastus`.
*   **Address Space:** A non-overlapping CIDR (e.g., `10.1.0.0/16`).
*   **Subnets:**
    1.  **`snet-aks-nodes`**:
        *   **Purpose:** Hosting AKS Nodes and Pods.
        *   **Size:** Minimum `/24` (Recommended `/22` for scale).
        *   **Delegation:** None (or specific to AKS if using advanced features).
    2.  **`snet-ingress`** (Optional but recommended):
        *   **Purpose:** Application Gateway or Load Balancers.
        *   **Size:** `/26` or `/28`.

### C. Identity (Managed Identity)
*   **Name:** `id-aks-sales-stage`.
*   **Purpose:** Control Plane identity for the AKS cluster.
*   **Role Assignments:**
    *   **`AcrPull`** on the **Permanent ACR** (created in step 1A).
    *   **`Network Contributor`** on the **`vnet-sales-stage-eastus`** (so AKS can configure Load Balancers).

---

## 3. Outputs Required
The `workloads` module must output the following so the App Repo can consume them:
*   `resource_group_name`
*   `vnet_id`
*   `subnet_id_aks_nodes`
*   `identity_id_aks` (The resource ID of the User Managed Identity)
*   `identity_client_id_aks` (The Client ID of the User Managed Identity)
