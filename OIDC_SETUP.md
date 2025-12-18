# GitHub OIDC Setup Guide for Azure

This guide walks through configuring OpenID Connect (OIDC) authentication between GitHub Actions and Azure, eliminating the need for long-lived service principal secrets.

**Context**: See [DECISIONS.md - Decision 9](DECISIONS.md#decision-9-cicd-authentication-method) for why we chose OIDC over service principal secrets.

---

## 📋 Overview

**What is OIDC?**
- GitHub Actions requests a temporary token from GitHub's OIDC provider
- Azure validates the token and grants access based on federated credentials
- No secrets stored in GitHub (only non-sensitive IDs: client ID, tenant ID)
- Tokens expire automatically (hours instead of years)

**Benefits**:
- ✅ Zero long-lived secrets in GitHub
- ✅ Automatic token rotation
- ✅ Microsoft best practice
- ✅ Audit trail via Azure AD logs
- ✅ No secret rotation burden

---

## 🎯 Prerequisites

Before starting, ensure you have:

1. **Azure CLI** installed and authenticated: `az login`
2. **GitHub repository** with admin access: `github.com:amaramdotme/A10_Corp-terraform.git`
3. **Azure permissions**: Ability to create App Registrations and assign RBAC roles
4. **Repository structure**: Foundation and workloads modules deployed

**Subscription IDs** (you'll need these):
- Root subscription: `fdb297a9-2ece-469c-808d-a8227259f6e8` (where Key Vault lives)
- HQ subscription: `da1ba383-2bf5-4ee9-8b5f-fc6effb0a100`
- Sales subscription: `385c6fcb-c70b-4aed-b745-76bd608303d7`
- Service subscription: `aef7255d-42b5-4f84-81f2-202191e8c7d1`

**Tenant ID**: `8116fad0-5032-463e-b911-cc6d1d75001d`

---

## 🔧 Step 1: Create Azure App Registration

### 1.1 Create the App Registration

```bash
# Create App Registration for GitHub Actions OIDC
az ad app create \
  --display-name "GitHub-OIDC-A10Corp-Terraform" \
  --sign-in-audience AzureADMyOrg

# Save the output - you'll need the appId (client ID)
```

**Expected Output**:
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  # ← Save this as AZURE_CLIENT_ID
  "displayName": "GitHub-OIDC-A10Corp-Terraform",
  "id": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
  ...
}
```

### 1.2 Create Service Principal

```bash
# Create service principal for the app registration
# Replace <appId> with the appId from step 1.1
az ad sp create --id <appId>

# Save the objectId from the output
```

**Expected Output**:
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "objectId": "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz",  # ← Save this for RBAC assignment
  ...
}
```

### 1.3 Save Values

**Record these values** (you'll need them later):
- `appId` → This is your **AZURE_CLIENT_ID**
- `objectId` → Service principal object ID for RBAC
- Tenant ID → **AZURE_TENANT_ID** (already known: `8116fad0-5032-463e-b911-cc6d1d75001d`)

---

## 🔐 Step 2: Configure Federated Credentials

Federated credentials establish trust between GitHub and Azure. You need **4 credentials total**:
- **1 for global** (foundation module - no environment)
- **3 for workloads** (dev, stage, prod environments)

### 2.1 Federated Credential for Global (Foundation Module)

```bash
# Replace <appId> with your client ID from Step 1
az ad app federated-credential create \
  --id <appId> \
  --parameters '{
    "name": "GitHubActions-Global",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:amaramdotme/A10_Corp-terraform:environment:global",
    "audiences": ["api://AzureADTokenExchange"],
    "description": "GitHub Actions OIDC for global infrastructure (foundation module - management groups)"
  }'
```

### 2.2 Federated Credential for Workloads-Dev Environment

```bash
az ad app federated-credential create \
  --id <appId> \
  --parameters '{
    "name": "GitHubActions-Workloads-Dev",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:amaramdotme/A10_Corp-terraform:environment:workloads-dev",
    "audiences": ["api://AzureADTokenExchange"],
    "description": "GitHub Actions OIDC for workloads dev environment"
  }'
```

### 2.3 Federated Credential for Workloads-Stage Environment

```bash
az ad app federated-credential create \
  --id <appId> \
  --parameters '{
    "name": "GitHubActions-Workloads-Stage",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:amaramdotme/A10_Corp-terraform:environment:workloads-stage",
    "audiences": ["api://AzureADTokenExchange"],
    "description": "GitHub Actions OIDC for workloads stage environment"
  }'
```

### 2.4 Federated Credential for Workloads-Prod Environment

```bash
az ad app federated-credential create \
  --id <appId> \
  --parameters '{
    "name": "GitHubActions-Workloads-Prod",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:amaramdotme/A10_Corp-terraform:environment:workloads-prod",
    "audiences": ["api://AzureADTokenExchange"],
    "description": "GitHub Actions OIDC for workloads prod environment"
  }'
```

### 2.5 Verify Federated Credentials

```bash
# List all federated credentials for the app
az ad app federated-credential list --id <appId>
```

**Expected**: You should see 4 federated credentials (global, workloads-dev, workloads-stage, workloads-prod).

**Important Notes**:
- The `subject` must EXACTLY match your GitHub environment names
- GitHub environments are case-sensitive (`global` ≠ `Global`)
- `global` is for foundation module infrastructure (not tied to dev/stage/prod)
- Workloads credentials are prefixed with `workloads-` to distinguish them

---

## 🛡️ Step 3: Assign RBAC Permissions

The service principal needs permissions to manage Azure resources. We'll grant Contributor role on all subscriptions plus Key Vault access.

### 3.1 Assign Contributor on Root Subscription

```bash
# Replace <objectId> with service principal objectId from Step 1.2
az role assignment create \
  --assignee <objectId> \
  --role "Contributor" \
  --scope "/subscriptions/fdb297a9-2ece-469c-808d-a8227259f6e8"
```

### 3.2 Assign Contributor on HQ Subscription

```bash
az role assignment create \
  --assignee <objectId> \
  --role "Contributor" \
  --scope "/subscriptions/da1ba383-2bf5-4ee9-8b5f-fc6effb0a100"
```

### 3.3 Assign Contributor on Sales Subscription

```bash
az role assignment create \
  --assignee <objectId> \
  --role "Contributor" \
  --scope "/subscriptions/385c6fcb-c70b-4aed-b745-76bd608303d7"
```

### 3.4 Assign Contributor on Service Subscription

```bash
az role assignment create \
  --assignee <objectId> \
  --role "Contributor" \
  --scope "/subscriptions/aef7255d-42b5-4f84-81f2-202191e8c7d1"
```

### 3.5 Assign Key Vault Secrets User (for fetching subscription IDs)

```bash
# Grant permission to read secrets from kv-root-terraform
az role assignment create \
  --assignee <objectId> \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/fdb297a9-2ece-469c-808d-a8227259f6e8/resourceGroups/rg-root-iac/providers/Microsoft.KeyVault/vaults/kv-root-terraform"
```

### 3.6 Assign Storage Blob Data Contributor (for Terraform state)

```bash
# Grant permission to read/write Terraform state files in storerootblob
az role assignment create \
  --assignee <objectId> \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/fdb297a9-2ece-469c-808d-a8227259f6e8/resourceGroups/rg-root-iac/providers/Microsoft.Storage/storageAccounts/storerootblob"
```

### 3.7 Verify RBAC Assignments

```bash
# List all role assignments for the service principal
az role assignment list --assignee <objectId> --all -o table
```

**Expected Output**:
| Role | Scope |
|------|-------|
| Contributor | /subscriptions/fdb297a9-2ece-469c-808d-a8227259f6e8 (root) |
| Contributor | /subscriptions/da1ba383-2bf5-4ee9-8b5f-fc6effb0a100 (hq) |
| Contributor | /subscriptions/385c6fcb-c70b-4aed-b745-76bd608303d7 (sales) |
| Contributor | /subscriptions/aef7255d-42b5-4f84-81f2-202191e8c7d1 (service) |
| Key Vault Secrets User | kv-root-terraform |
| Storage Blob Data Contributor | storerootblob |

**Optional - Management Group Permissions**:
If you need to modify management groups via CI/CD:
```bash
# Assign Management Group Contributor at tenant root
az role assignment create \
  --assignee <objectId> \
  --role "Management Group Contributor" \
  --scope "/providers/Microsoft.Management/managementGroups/8116fad0-5032-463e-b911-cc6d1d75001d"
```

---

## 🔑 Step 4: Configure GitHub Repository

### 4.1 Create GitHub Environments

GitHub environments provide isolation for secrets/variables and enable deployment protection rules.

**Navigate to**: `https://github.com/amaramdotme/A10_Corp-terraform/settings/environments`

**Create four environments**:
1. `global` (foundation module - management groups, no environment)
2. `workloads-dev` (workloads development)
3. `workloads-stage` (workloads staging)
4. `workloads-prod` (workloads production - enable protection rules)

**Global Environment** (recommended):
- ✅ Required reviewers: Add yourself (global infrastructure affects all environments)
- ✅ Deployment branches: Only `main` branch

**Workloads Production Protection Rules** (recommended):
- ✅ Required reviewers: Add yourself
- ✅ Wait timer: 0 minutes (or add delay for safety)
- ✅ Deployment branches: Only `main` branch

### 4.2 Configure Repository Variables (Non-Sensitive)

These are **non-sensitive** and can be stored as GitHub Variables (not Secrets).

**Navigate to**: `Settings → Secrets and variables → Actions → Variables`

**Add Repository Variables** (available to all environments):

| Name | Value | Description |
|------|-------|-------------|
| `AZURE_CLIENT_ID` | `<appId from Step 1>` | Application (client) ID |
| `AZURE_TENANT_ID` | `8116fad0-5032-463e-b911-cc6d1d75001d` | Azure AD tenant ID |

**Why Variables instead of Secrets?**
- Client ID and Tenant ID are not authentication credentials
- They're included in OIDC token exchange (not sensitive)
- Using Variables allows them to be visible in workflow logs for debugging

### 4.3 Configure Repository Secrets (Sensitive)

**Navigate to**: `Settings → Secrets and variables → Actions → Secrets`

**Add Repository Secrets** (available to all environments):

| Name | Value | Description |
|------|-------|-------------|
| `AZURE_ROOT_SUBSCRIPTION_ID` | `fdb297a9-2ece-469c-808d-a8227259f6e8` | Root subscription (where Key Vault lives) |

**Why Secrets?**
- Subscription IDs provide reconnaissance information for attackers
- Defense-in-depth: Don't expose infrastructure topology publicly
- Best practice for public repositories

**Note**: HQ, Sales, and Service subscription IDs are fetched from Key Vault by Terraform (not stored in GitHub).

### 4.4 Verify Configuration

**Check Repository Variables**:
```bash
# Via GitHub CLI (if installed)
gh variable list

# Expected output:
AZURE_CLIENT_ID    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AZURE_TENANT_ID    8116fad0-5032-463e-b911-cc6d1d75001d
```

**Check Repository Secrets**:
```bash
# Via GitHub CLI
gh secret list

# Expected output:
AZURE_ROOT_SUBSCRIPTION_ID  Updated YYYY-MM-DD
```

---

## ✅ Step 5: Test OIDC Authentication

### 5.1 Test Manually via GitHub Actions UI

**Test Global/Foundation Module**:
1. **Navigate to**: `Actions` tab in GitHub repository
2. **Select**: "Terraform Foundation" workflow (or similar)
3. **Click**: "Run workflow" dropdown
4. **Configure**:
   - Environment: `global`
   - Action: `plan`
5. **Click**: "Run workflow"

**Test Workloads Module (Dev)**:
1. **Navigate to**: `Actions` tab in GitHub repository
2. **Select**: "Terraform Workloads" workflow (or similar)
3. **Click**: "Run workflow" dropdown
4. **Configure**:
   - Environment: `workloads-dev`
   - Action: `plan`
5. **Click**: "Run workflow"

### 5.2 Expected Behavior

**Success indicators**:
- ✅ "Azure Login via OIDC" step completes successfully
- ✅ Terraform init/validate/plan execute without authentication errors
- ✅ Terraform can read from Key Vault (fetches subscription IDs)
- ✅ Workflow logs show: "Login successful"

**Common Errors** (see Troubleshooting section below):
- ❌ "AADSTS70021: No matching federated identity record found"
- ❌ "Error: Unable to get Key Vault secret"
- ❌ "Error: subscription ID could not be determined"

### 5.3 Test with Azure CLI (Optional Local Test)

You can simulate OIDC locally to verify the service principal works:

```bash
# Login as the service principal (using client secret for testing)
# Note: This requires creating a client secret temporarily
az login --service-principal \
  --username <appId> \
  --password <client-secret> \
  --tenant 8116fad0-5032-463e-b911-cc6d1d75001d

# Verify access to subscriptions
az account list -o table

# Verify Key Vault access
az keyvault secret show \
  --vault-name kv-root-terraform \
  --name terraform-dev-hq-sub-id \
  --query value -o tsv

# Logout
az logout
```

**Note**: Client secret is only for testing. OIDC doesn't use secrets - delete the secret after testing.

---

## 🐛 Troubleshooting

### Error: "AADSTS70021: No matching federated identity record found"

**Cause**: Federated credential subject doesn't match GitHub environment.

**Solutions**:
1. Verify environment names match exactly (case-sensitive):
   ```bash
   az ad app federated-credential list --id <appId>
   # Check subjects match:
   # - "repo:amaramdotme/A10_Corp-terraform:environment:global"
   # - "repo:amaramdotme/A10_Corp-terraform:environment:workloads-dev"
   # - "repo:amaramdotme/A10_Corp-terraform:environment:workloads-stage"
   # - "repo:amaramdotme/A10_Corp-terraform:environment:workloads-prod"
   ```

2. Verify GitHub environments exist:
   - Go to: `Settings → Environments`
   - Ensure `global`, `workloads-dev`, `workloads-stage`, `workloads-prod` environments exist

3. Check workflow is using correct environment:
   ```yaml
   # For foundation workflow
   environment: global

   # For workloads workflow
   environment: workloads-${{ github.event.inputs.environment }}
   ```

### Error: "Unable to get Key Vault secret"

**Cause**: Service principal lacks Key Vault access.

**Solutions**:
1. Verify RBAC assignment:
   ```bash
   az role assignment list --assignee <objectId> --all -o table | grep "Key Vault"
   ```

2. Check Key Vault access policies (if using legacy policies):
   ```bash
   az keyvault show --name kv-root-terraform --query "properties.accessPolicies"
   ```

3. Ensure RBAC authorization is enabled on Key Vault:
   ```bash
   az keyvault show --name kv-root-terraform --query "properties.enableRbacAuthorization"
   # Should be: true
   ```

### Error: "subscription ID could not be determined"

**Cause**: `ARM_SUBSCRIPTION_ID` environment variable not set or incorrect.

**Solutions**:
1. Verify `azure/login@v2` action sets environment variables:
   ```yaml
   - name: Azure Login via OIDC
     uses: azure/login@v2
     with:
       client-id: ${{ vars.AZURE_CLIENT_ID }}
       tenant-id: ${{ vars.AZURE_TENANT_ID }}
       subscription-id: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}
   ```

2. Explicitly set ARM variables in Terraform steps:
   ```yaml
   env:
     ARM_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
     ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
     ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}
     ARM_USE_OIDC: true
   ```

### Error: "Error validating provider credentials"

**Cause**: OIDC token expired or invalid.

**Solutions**:
1. Ensure `permissions: id-token: write` is set at workflow level
2. Verify `ARM_USE_OIDC: true` is set in environment variables
3. Check that client ID and tenant ID are correct in GitHub variables

### Error: "Insufficient privileges to complete the operation"

**Cause**: Service principal lacks RBAC permissions.

**Solutions**:
1. Verify Contributor role on all subscriptions:
   ```bash
   az role assignment list --assignee <objectId> --all -o table
   ```

2. For management group operations, add Management Group Contributor role:
   ```bash
   az role assignment create \
     --assignee <objectId> \
     --role "Management Group Contributor" \
     --scope "/providers/Microsoft.Management/managementGroups/8116fad0-5032-463e-b911-cc6d1d75001d"
   ```

---

## 📊 Verification Checklist

Before considering OIDC setup complete, verify:

- [ ] **App Registration created** with correct name
- [ ] **Service Principal created** and objectId recorded
- [ ] **4 Federated Credentials** configured (global, workloads-dev, workloads-stage, workloads-prod)
- [ ] **RBAC assignments** on all 4 subscriptions (Contributor)
- [ ] **Key Vault RBAC** assigned (Key Vault Secrets User)
- [ ] **Storage Account RBAC** assigned (Storage Blob Data Contributor)
- [ ] **GitHub Environments** created (global, workloads-dev, workloads-stage, workloads-prod)
- [ ] **GitHub Variables** set (AZURE_CLIENT_ID, AZURE_TENANT_ID)
- [ ] **GitHub Secrets** set (AZURE_ROOT_SUBSCRIPTION_ID)
- [ ] **Test global/foundation workflow** runs successfully
- [ ] **Test workloads-dev workflow** runs successfully
- [ ] **Terraform plan** completes without authentication errors in both modules
- [ ] **Key Vault access** works (subscription IDs fetched successfully)
- [ ] **Terraform state** reads/writes successfully to storerootblob

---

## 🔒 Security Best Practices

1. **Principle of Least Privilege**:
   - Grant only Contributor (not Owner) on subscriptions
   - Limit Key Vault access to Secrets User (not Administrator)

2. **Environment Protection**:
   - Enable required reviewers for production deployments
   - Use deployment branches to limit which branches can deploy

3. **Audit Logging**:
   - Monitor Azure AD sign-in logs for service principal activity
   - Enable Key Vault logging to track secret access

4. **Regular Reviews**:
   - Audit RBAC assignments quarterly
   - Review federated credentials for orphaned entries
   - Check GitHub Actions logs for suspicious activity

5. **Conditional Access** (if using Azure AD Premium):
   - Require trusted locations for service principal sign-ins
   - Enable Multi-Factor Authentication for production approvals

---

## 📚 Additional Resources

- [Microsoft Docs: Use OIDC with GitHub Actions](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [GitHub Docs: OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Azure RBAC Built-in Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [DECISIONS.md - Decision 9](DECISIONS.md#decision-9-cicd-authentication-method)

---

## 🎯 Next Steps After OIDC Setup

Once OIDC is configured and tested:

1. **Update NEXTSTEPS.md**: Mark Priority #7 as complete
2. **Update ARCHITECTURE.md**: Document OIDC configuration
3. **Deploy Stage Environment**: Test OIDC with stage
4. **Deploy Prod Environment**: Test OIDC with production (with approvals)
5. **Enable Branch Protection**: Require PR reviews for main branch
6. **Add Pre-commit Hooks**: terraform fmt, validate, tflint

---

**Maintained By**: Infrastructure Team
**Last Updated**: 2025-12-18
**Status**: Ready for implementation
