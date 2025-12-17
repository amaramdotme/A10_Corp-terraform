# OIDC Setup Details

# (1) Azure Entra ID -> App registrations
    App Name: github-actions-terraform-a10corp
    App(Client) ID: 185e1713-2bac-4430-b497-481805d047cb
    Directory(tenant) ID: 8116fad0-5032-463e-b911-cc6d1d75001d

# (2) Azure Entra ID -> Add Federated Credential 
    github-actions-dev
    github-actions-stage
    github-actions-prod

# (3) Azure Entra ID -> Assign Azure Permissions
    Contributor role -> sub-root-tenant
    Contributor role -> sub-a10corp-sales

# (4) Azure Entra ID -> Add Management Group Permissions 
    Contributor role -> mg-a10corp-hq

# (5) Configure GitHub -> Variables
   env: dev; env_variables: clientID, tenantID, subscriptionID; protection: <PENDING - need to come back after repo is public>



-----------------------------------------------------

Step-by-Step: Azure Portal
1. Create App Registration
Go to Azure Portal → Microsoft Entra ID (formerly Azure AD)
Click App registrations (left sidebar)
Click + New registration
Fill in:
Name: github-actions-terraform-a10corp
Supported account types: "Accounts in this organizational directory only"
Redirect URI: Leave blank
Click Register
Note down these values (you'll need them):
Application (client) ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Directory (tenant) ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
2. Add Federated Credential (OIDC)
In your App Registration, click Certificates & secrets (left sidebar)
Click the Federated credentials tab
Click + Add credential
Select GitHub Actions deploying Azure resources
Fill in:
Organization: Your GitHub username/org (e.g., yourusername)
Repository: Your repo name (e.g., A10_Corp)
Entity type:
Select Environment
Environment name: dev (create one for each environment)
Name: github-actions-dev (just a friendly name)
Click Add
Repeat for other environments:
Add another credential for stage environment
Add another credential for prod environment
3. Assign Azure Permissions
The service principal needs permissions to manage resources:
Go to Subscriptions
Select your shared subscription (fdb297a9-2ece-469c-808d-a8227259f6e8)
Click Access control (IAM) (left sidebar)
Click + Add → Add role assignment
Select role:
Role: Contributor (or Owner if you need to manage IAM)
Click Next
Click + Select members
Search for github-actions-terraform-a10corp
Select it and click Select
Click Review + assign
Repeat for other subscriptions:
Sales subscription (385c6fcb-c70b-4aed-b745-76bd608303d7)
Service subscription (aef7255d-42b5-4f84-81f2-202191e8c7d1)
4. Add Management Group Permissions
For managing management groups:
Go to Management groups
Select Tenant Root Group (or your highest-level MG)
Click Access control (IAM)
Click + Add → Add role assignment
Select Management Group Contributor
Add the github-actions-terraform-a10corp service principal
Click Review + assign
What You'll Have
After completing these steps, you'll have:
✅ Service principal (no client secret needed!)
✅ Federated credentials for dev, stage, prod environments
✅ Contributor access on all 3 subscriptions
✅ Management Group Contributor access
Next: Configure GitHub
You'll need to add these as GitHub Variables (not secrets, since they're not sensitive):
Go to your GitHub repo → Settings → Environments
Create environment: dev
Add Environment variables:
AZURE_CLIENT_ID: (from step 1)
AZURE_TENANT_ID: (from step 1)
AZURE_SUBSCRIPTION_ID: fdb297a9-2ece-469c-808d-a8227259f6e8
Would you like me to create the GitHub Actions workflow file once you've completed the Azure Portal setup?


GitHub Environment Setup (via Web Portal)
Step 1: Navigate to Repository Settings
Go to https://github.com/GoldenSapien/A10_Corp-terraform
Click Settings tab (top right)
In the left sidebar, scroll down to Environments (under "Security" section)
Click Environments
Step 2: Create Dev Environment
Click New environment button
Name: dev
Click Configure environment
Add Environment Variables (not secrets - these are public IDs):
Click Add variable
Name: AZURE_CLIENT_ID
Value: 185e1713-2bac-4430-b497-481805d047cb
Click Add variable
Click Add variable again
Name: AZURE_TENANT_ID
Value: 8116fad0-5032-463e-b911-cc6d1d75001d
Click Add variable
Click Add variable again
Name: AZURE_SUBSCRIPTION_ID
Value: fdb297a9-2ece-469c-808d-a8227259f6e8 (shared/root subscription)
Click Add variable
(Optional) Add Environment Protection Rules:
Check Required reviewers if you want manual approval for dev deployments
Set Wait timer if needed
Click Save protection rules
Step 3: Create Stage Environment
Go back to Environments page
Click New environment
Name: stage
Click Configure environment
Add the same 3 variables:
AZURE_CLIENT_ID: 185e1713-2bac-4430-b497-481805d047cb
AZURE_TENANT_ID: 8116fad0-5032-463e-b911-cc6d1d75001d
AZURE_SUBSCRIPTION_ID: 385c6fcb-c70b-4aed-b745-76bd608303d7 (sales subscription)
Step 4: Create Prod Environment
Go back to Environments page
Click New environment
Name: prod
Click Configure environment
Add the same 3 variables:
AZURE_CLIENT_ID: 185e1713-2bac-4430-b497-481805d047cb
AZURE_TENANT_ID: 8116fad0-5032-463e-b911-cc6d1d75001d
AZURE_SUBSCRIPTION_ID: aef7255d-42b5-4f84-81f2-202191e8c7d1 (marketing subscription)
(Recommended) Add Protection Rules for Prod:
Check Required reviewers (select yourself or team members)
This prevents accidental production deployments
Click Save protection rules



------------------------------------------------

setting tfvars local & github actions 

Final GitHub Environment Configuration
Each environment (dev/stage/prod) now has:
Variables (Public, visible in logs):
✅ AZURE_CLIENT_ID - App Registration ID
✅ AZURE_TENANT_ID - Tenant ID
Secrets (Hidden, redacted in logs):
🔒 AZURE_ROOT_SUBSCRIPTION_ID - Shared/root subscription
🔒 AZURE_SALES_SUBSCRIPTION_ID - Sales subscription
🔒 AZURE_SERVICE_SUBSCRIPTION_ID - Service/marketing subscription
This provides better security while keeping the non-sensitive IDs (client/tenant) visible for debugging. Now we're ready to create the GitHub Actions workflow! Should I proceed with creating .github/workflows/terraform-deploy.yml?
Now if I were plan and apply this from my local How do we manage that
Great question! You need a strategy for local development that works alongside the GitHub Actions CI/CD. Here are the options:
Option 1: Keep .tfvars Files Local (Current Approach) ✅
How it works:
Keep environments/*.tfvars with all values gitignored
Use them locally with terraform plan -var-file="environments/dev.tfvars"
GitHub Actions uses secrets instead
Pros:
✅ Simple for local development
✅ No changes needed to workflow
✅ Works right now
Cons:
❌ .tfvars files not versioned (team members need to recreate)
❌ Dual source of truth (local .tfvars vs GitHub secrets)
Option 2: Use Environment Variables Locally (Recommended) 🔒
How it works:
Remove sensitive values from .tfvars files
Set environment variables locally: export TF_VAR_subscription_id="xxx"
Terraform automatically reads TF_VAR_* environment variables
Local workflow:

# Set environment variables (one time per session)
export TF_VAR_subscription_id="fdb297a9-2ece-469c-808d-a8227259f6e8"
export TF_VAR_sales_subscription_id="385c6fcb-c70b-4aed-b745-76bd608303d7"
export TF_VAR_service_subscription_id="aef7255d-42b5-4f84-81f2-202191e8c7d1"
export TF_VAR_tenant_id="8116fad0-5032-463e-b911-cc6d1d75001d"

# Run terraform (still need -var-file for non-sensitive values)
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
What to keep in .tfvars:

# environments/dev.tfvars (safe to commit)
org_name    = "a10corp"
environment = "dev"
location    = "eastus"

common_tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "A10Corp"
}

# Sensitive values come from TF_VAR_* environment variables
# subscription_id        = <from TF_VAR_subscription_id>
# sales_subscription_id  = <from TF_VAR_sales_subscription_id>
# service_subscription_id = <from TF_VAR_service_subscription_id>
# tenant_id              = <from TF_VAR_tenant_id>
Option 3: Use a .env File (Easiest for Local) 💡
How it works:
Create secure/.env file (gitignored)
Source it before running terraform
Same values as GitHub secrets
Setup:

# Create secure/.env (already gitignored)
cat > secure/.env << 'EOF'
export TF_VAR_subscription_id="fdb297a9-2ece-469c-808d-a8227259f6e8"
export TF_VAR_sales_subscription_id="385c6fcb-c70b-4aed-b745-76bd608303d7"
export TF_VAR_service_subscription_id="aef7255d-42b5-4f84-81f2-202191e8c7d1"
export TF_VAR_tenant_id="8116fad0-5032-463e-b911-cc6d1d75001d"
EOF
Local workflow:

# Load environment variables
source secure/.env

# Run terraform
cd terraform/
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
Pros:
✅ Single source for sensitive values
✅ Easy to use locally
✅ .env already gitignored
✅ Can commit .tfvars with non-sensitive values
Cons:
❌ Need to remember to source the file
My Recommendation: Option 3 (.env file)
This gives you:
Local development: source secure/.env then run terraform
CI/CD: GitHub Actions uses secrets automatically
Version control: Commit .tfvars with non-sensitive config
Security: secure/.env is gitignored, never committed
Would you like me to:
Create the secure/.env.example template?
Update .tfvars files to remove sensitive values?
Add documentation for this workflow?
So when we run the terraform plan command within the Github CICD action workflow How would we reference the tenant the subscription ID etc
Great question! In the GitHub Actions workflow, you'll reference them using both variables and secrets:
In GitHub Actions Workflow

name: Terraform Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - stage
          - prod

jobs:
  terraform:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Azure Login via OIDC
        uses: azure/login@v1
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}  # Primary subscription for login
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Plan
        run: terraform plan -var-file="environments/${{ github.event.inputs.environment }}.tfvars" -out=tfplan
        working-directory: ./terraform
        env:
          # Pass secrets as TF_VAR_* environment variables
          TF_VAR_subscription_id: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}
          TF_VAR_sales_subscription_id: ${{ secrets.AZURE_SALES_SUBSCRIPTION_ID }}
          TF_VAR_service_subscription_id: ${{ secrets.AZURE_SERVICE_SUBSCRIPTION_ID }}
          TF_VAR_tenant_id: ${{ vars.AZURE_TENANT_ID }}
      
      - name: Terraform Apply
        if: github.event.inputs.environment != 'prod'  # Optional: require manual approval for prod
        run: terraform apply tfplan
        working-directory: ./terraform
        env:
          # Same environment variables needed for apply
          TF_VAR_subscription_id: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}
          TF_VAR_sales_subscription_id: ${{ secrets.AZURE_SALES_SUBSCRIPTION_ID }}
          TF_VAR_service_subscription_id: ${{ secrets.AZURE_SERVICE_SUBSCRIPTION_ID }}
          TF_VAR_tenant_id: ${{ vars.AZURE_TENANT_ID }}
Key Points
1. Variables (Non-sensitive)

${{ vars.AZURE_CLIENT_ID }}     # Visible in logs
${{ vars.AZURE_TENANT_ID }}      # Visible in logs
2. Secrets (Sensitive)

${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}     # Redacted as *** in logs
${{ secrets.AZURE_SALES_SUBSCRIPTION_ID }}    # Redacted as *** in logs
${{ secrets.AZURE_SERVICE_SUBSCRIPTION_ID }}  # Redacted as *** in logs
3. Terraform Receives Them via TF_VAR_*
Terraform automatically picks up environment variables prefixed with TF_VAR_:

# In workflow
env:
  TF_VAR_subscription_id: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}

# Terraform sees it as
variable "subscription_id" {
  # Automatically populated from TF_VAR_subscription_id
}
What .tfvars Files Contain
The .tfvars files only contain non-sensitive configuration:

# environments/dev.tfvars (safe to commit)
org_name    = "a10corp"
environment = "dev"
location    = "eastus"

common_tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "A10Corp"
}

# Sensitive values NOT here - they come from GitHub secrets via TF_VAR_*
So the workflow flow is:
Checkout code → Gets .tfvars with non-sensitive config
Set env vars → TF_VAR_* from GitHub secrets
Run terraform → Terraform merges both sources
Non-sensitive from .tfvars
Sensitive from TF_VAR_* environment variables
Make sense?
Let's say we use option one keep tfwares files local, In a typical enterprise when there are multip developers in A team where would they store TFvar files And share among devs devs If it is not in the repo
Excellent real-world question! This is a common enterprise challenge. Here are the typical approaches:
Enterprise Solutions for Sharing .tfvars Files
Option 1: Secure Shared Storage (Most Common) 🔒
Azure Key Vault / HashiCorp Vault / AWS Secrets Manager

# Developers fetch .tfvars from Key Vault
az keyvault secret show \
  --vault-name "a10corp-terraform-vault" \
  --name "dev-tfvars" \
  --query "value" -o tsv > environments/dev.tfvars

# Then use normally
terraform plan -var-file="environments/dev.tfvars"
Pros:
✅ Centralized, audited access
✅ Version control for secrets
✅ Access control per developer
✅ Audit logs (who accessed when)
Cons:
❌ Requires setup and permissions
❌ Extra step before running terraform
Option 2: Encrypted Git (GitCrypt / SOPS) 🔐
Tools like git-crypt or Mozilla SOPS

# Setup (one time)
git-crypt init
git-crypt add-gpg-user developer@company.com

# Mark .tfvars as encrypted
echo "environments/*.tfvars filter=git-crypt diff=git-crypt" >> .gitattributes

# After setup, files are:
# - Encrypted in git (safe to commit)
# - Decrypted locally for authorized developers
Pros:
✅ Files in repo (versioned, backed up)
✅ Works with normal git workflow
✅ Decryption automatic for authorized devs
Cons:
❌ All devs need GPG keys
❌ Complex key management
❌ Risk if someone loses private key
Option 3: Terraform Cloud / Enterprise (Enterprise Standard) ☁️
HashiCorp Terraform Cloud/Enterprise
Variables stored in Terraform Cloud workspace
No local .tfvars files needed
All runs happen in cloud (or self-hosted)

# Local development
terraform login  # One-time setup
terraform plan   # Uses remote state and variables
Pros:
✅ Enterprise-grade solution
✅ Remote state included
✅ Role-based access control
✅ Audit trails
✅ No local files
Cons:
❌ Requires Terraform Cloud/Enterprise license
❌ Learning curve
❌ All runs must go through cloud (slower for local testing)
Option 4: Team Password Manager / 1Password 🔑
Shared vault in 1Password/LastPass/Bitwarden
Store .tfvars content as secure notes
Developers manually copy when needed
Simple but not automated
Pros:
✅ Simple, most companies already have this
✅ Easy to update
✅ Access control built-in
Cons:
❌ Manual copy/paste
❌ No version control
❌ Risk of outdated copies
Option 5: Private S3/Blob Storage + IAM 📦
Cloud storage with access control

# Fetch from Azure Blob Storage
az storage blob download \
  --account-name a10corpterraform \
  --container-name tfvars \
  --name dev.tfvars \
  --file environments/dev.tfvars

# Or from AWS S3
aws s3 cp s3://a10corp-terraform/dev.tfvars environments/
Pros:
✅ Cloud-native solution
✅ Versioning available
✅ IAM/RBAC for access
✅ Audit logs
Cons:
❌ Manual fetch step
❌ Can get out of sync
My Recommendation for A10 Corp
Short term (Current setup): Keep .tfvars gitignored, each dev maintains their own copy
Share via secure channel (1Password, encrypted email)
Document in onboarding guide
Medium term (3-6 months): Azure Key Vault + automation

# Create helper script: scripts/fetch-tfvars.sh
#!/bin/bash
ENV=${1:-dev}
az keyvault secret show \
  --vault-name "kv-a10corp-terraform" \
  --name "tfvars-${ENV}" \
  --query "value" -o tsv > "environments/${ENV}.tfvars"
echo "✓ Fetched ${ENV}.tfvars from Key Vault"
Long term (Enterprise scale): Terraform Cloud/Enterprise
As team grows beyond 5-10 people
When you need governance/compliance
When remote state management becomes critical
Quick Win: Create a Secure .env Template
For now, let me create a template developers can use: Would you like me to:
Create secure/.env.example template for local development?
Create secure/.tfvars.example template files?
Add documentation for sharing strategy?
This way new developers can quickly set up their local environment while you figure out the long-term strategy.
OK if we were to pick option one keep local environment tfvars not checked into repo but stored in azure vault how would github actions worklfow pick up the attributes that are in tfvars ?
Great question! If .tfvars files are in Azure Key Vault and NOT in the repo, the GitHub Actions workflow needs to fetch them first. Here's how:
GitHub Actions Workflow with Azure Key Vault

name: Terraform Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - stage
          - prod

jobs:
  terraform:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Azure Login via OIDC
        uses: azure/login@v1
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}
      
      # NEW STEP: Fetch .tfvars from Azure Key Vault
      - name: Fetch tfvars from Key Vault
        run: |
          az keyvault secret show \
            --vault-name "kv-a10corp-terraform" \
            --name "tfvars-${{ github.event.inputs.environment }}" \
            --query "value" -o tsv > terraform/environments/${{ github.event.inputs.environment }}.tfvars
          
          echo "✓ Fetched ${{ github.event.inputs.environment }}.tfvars from Key Vault"
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Plan
        run: terraform plan -var-file="environments/${{ github.event.inputs.environment }}.tfvars" -out=tfplan
        working-directory: ./terraform
        env:
          # You can STILL pass secrets as env vars for extra security
          TF_VAR_subscription_id: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}
          TF_VAR_sales_subscription_id: ${{ secrets.AZURE_SALES_SUBSCRIPTION_ID }}
          TF_VAR_service_subscription_id: ${{ secrets.AZURE_SERVICE_SUBSCRIPTION_ID }}
          TF_VAR_tenant_id: ${{ vars.AZURE_TENANT_ID }}
      
      - name: Terraform Apply
        run: terraform apply tfplan
        working-directory: ./terraform
        env:
          TF_VAR_subscription_id: ${{ secrets.AZURE_ROOT_SUBSCRIPTION_ID }}
          TF_VAR_sales_subscription_id: ${{ secrets.AZURE_SALES_SUBSCRIPTION_ID }}
          TF_VAR_service_subscription_id: ${{ secrets.AZURE_SERVICE_SUBSCRIPTION_ID }}
          TF_VAR_tenant_id: ${{ vars.AZURE_TENANT_ID }}
Key Vault Setup
1. Create Key Vault (if not exists)

az keyvault create \
  --name "kv-a10corp-terraform" \
  --resource-group "rg-a10corp-shared-dev" \
  --location "eastus"
2. Store .tfvars as Secrets

# Store dev.tfvars
az keyvault secret set \
  --vault-name "kv-a10corp-terraform" \
  --name "tfvars-dev" \
  --file "terraform/environments/dev.tfvars"

# Store stage.tfvars
az keyvault secret set \
  --vault-name "kv-a10corp-terraform" \
  --name "tfvars-stage" \
  --file "terraform/environments/stage.tfvars"

# Store prod.tfvars
az keyvault secret set \
  --vault-name "kv-a10corp-terraform" \
  --name "tfvars-prod" \
  --file "terraform/environments/prod.tfvars"
3. Grant GitHub Service Principal Access

# Grant the OIDC service principal access to read secrets
az keyvault set-policy \
  --name "kv-a10corp-terraform" \
  --object-id "7e51fa49-f581-497d-b960-46a65301c155" \
  --secret-permissions get list
How It Works
GitHub Actions authenticates → Uses OIDC (no secrets stored in GitHub!)
Fetches .tfvars → Downloads from Key Vault to runner
Runs Terraform → Uses the fetched .tfvars file
File is ephemeral → Deleted when runner terminates
Hybrid Approach (Best of Both Worlds)
You can split sensitive and non-sensitive values:
In Repo: environments/dev.tfvars (non-sensitive)

# Safe to commit - no sensitive data
org_name    = "a10corp"
environment = "dev"
location    = "eastus"

common_tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "A10Corp"
}
In Key Vault: tfvars-dev-sensitive (sensitive only)

# Stored in Key Vault - sensitive IDs
subscription_id         = "fdb297a9-2ece-469c-808d-a8227259f6e8"
sales_subscription_id   = "385c6fcb-c70b-4aed-b745-76bd608303d7"
service_subscription_id = "aef7255d-42b5-4f84-81f2-202191e8c7d1"
tenant_id               = "8116fad0-5032-463e-b911-cc6d1d75001d"
Workflow combines both:

- name: Fetch sensitive tfvars from Key Vault
  run: |
    az keyvault secret show \
      --vault-name "kv-a10corp-terraform" \
      --name "tfvars-${{ github.event.inputs.environment }}-sensitive" \
      --query "value" -o tsv > terraform/environments/${{ github.event.inputs.environment }}-sensitive.tfvars

- name: Terraform Plan
  run: |
    terraform plan \
      -var-file="environments/${{ github.event.inputs.environment }}.tfvars" \
      -var-file="environments/${{ github.event.inputs.environment }}-sensitive.tfvars" \
      -out=tfplan
Summary
With Option 1 + Key Vault:
✅ .tfvars not in repo (secure)
✅ Centrally managed (team consistency)
✅ GitHub Actions fetches on-demand
✅ Ephemeral (no files left on runner)
✅ Access controlled via Azure RBAC
✅ Audit logs (who accessed when)