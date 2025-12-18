# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the A10 Corp Terraform infrastructure.

## Available Workflows

### 1. Test OIDC Authentication (`test-oidc.yml`)

**Purpose**: Test OIDC authentication setup without deploying any infrastructure.

**When to use**:
- After initial OIDC setup
- To verify credentials are working
- To troubleshoot authentication issues

**How to run**:
1. Go to GitHub: `Actions` → `Test OIDC Authentication`
2. Click `Run workflow`
3. Select environment: `global`, `dev`, `stage`, or `prod`
4. Click `Run workflow`

**What it tests**:
- ✅ Azure CLI authentication via OIDC
- ✅ Access to all 4 subscriptions (Root, HQ, Sales, Service)
- ✅ Key Vault access (read secrets)
- ✅ Storage Account access (list containers)
- ✅ RBAC role assignments

**Expected output**:
- All 5 tests should pass with green checkmarks
- Workflow should complete in ~1-2 minutes

**Troubleshooting**:
- If authentication fails, check federated credentials match environment names
- If subscription access fails, verify RBAC assignments
- If Key Vault fails, check Key Vault Secrets User role
- If Storage fails, check Storage Blob Data Contributor role

---

## Workflow Structure

```
.github/
├── workflows/
│   ├── README.md              # This file
│   └── test-oidc.yml          # OIDC test workflow
└── scripts/
    └── test_oidc.py           # Python test script
```

## Environment Configuration

All workflows use these GitHub configurations:

**Variables** (Settings → Secrets and variables → Actions → Variables):
- `AZURE_CLIENT_ID`: App registration client ID
- `AZURE_TENANT_ID`: Azure AD tenant ID

**Secrets** (Settings → Secrets and variables → Actions → Secrets):
- `AZURE_ROOT_SUBSCRIPTION_ID`: Root subscription ID

**Environments** (Settings → Environments):
- `global`: Foundation module (main branch only, requires approval)
- `dev`: Development workloads (any branch)
- `stage`: Staging workloads
- `prod`: Production workloads (main branch only, requires approval)

## Required Permissions

All workflows that use OIDC require:

```yaml
permissions:
  id-token: write  # Required for OIDC token
  contents: read   # Required to checkout code
```

## Azure Authentication

All workflows use the same Azure login pattern:

```yaml
- name: Azure Login via OIDC
  uses: azure/login@v2
  with:
    client-id: ${{ vars.AZURE_CLIENT_ID }}
    tenant-id: ${{ vars.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}
```

This provides zero-secret authentication via federated credentials.

## Next Steps

After OIDC test passes:
1. Create Terraform deployment workflows
2. Test with `terraform plan` in dev
3. Deploy to dev/stage/prod environments
