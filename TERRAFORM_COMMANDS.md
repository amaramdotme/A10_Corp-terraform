# Terraform Commands Reference

This document provides a comprehensive reference of the most commonly used Terraform commands.

---

## Essential Commands (Daily Use)

| Command | Purpose | Example |
|---------|---------|---------|
| `terraform init` | Initialize working directory, download providers | `terraform init` |
| `terraform plan` | Preview changes before applying | `terraform plan -out=tfplan` |
| `terraform apply` | Create/update infrastructure | `terraform apply tfplan` |
| `terraform destroy` | Destroy all managed infrastructure | `terraform destroy` |
| `terraform validate` | Check configuration syntax | `terraform validate` |
| `terraform fmt` | Format code to canonical style | `terraform fmt -recursive` |

### Examples

```bash
# Initialize Terraform (first time or after adding providers)
terraform init

# Upgrade providers to latest version
terraform init -upgrade

# Validate configuration
terraform validate

# Format all .tf files
terraform fmt -recursive

# Preview changes
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Apply saved plan
terraform apply tfplan

# Apply with auto-approve (use with caution!)
terraform apply -auto-approve

# Destroy specific resource
terraform destroy -target=azurerm_resource_group.example

# Destroy everything (use with extreme caution!)
terraform destroy
```

---

## State Management Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `terraform state list` | List resources in state | `terraform state list` |
| `terraform state show` | Show details of a resource | `terraform state show azurerm_resource_group.shared_common` |
| `terraform state rm` | Remove resource from state | `terraform state rm azurerm_resource_group.old` |
| `terraform state mv` | Move/rename resource in state | `terraform state mv old_name new_name` |
| `terraform import` | Import existing resource into state | `terraform import azurerm_resource_group.example /subscriptions/.../resourceGroups/myRG` |
| `terraform state pull` | Download and display remote state | `terraform state pull` |
| `terraform state push` | Upload local state to remote | `terraform state push` |

### Examples

```bash
# List all resources in state
terraform state list

# Show details of a specific resource
terraform state show azurerm_resource_group.shared_common

# Remove a resource from state (doesn't delete actual resource)
terraform state rm azurerm_resource_group.old

# Rename a resource in state
terraform state mv azurerm_resource_group.old azurerm_resource_group.new

# Import existing Azure resource group into Terraform state
terraform import azurerm_resource_group.shared_common /subscriptions/fdb297a9-2ece-469c-808d-a8227259f6e8/resourceGroups/rg-a10-shared-common

# View current state
terraform state pull > current-state.json
```

---

## Information & Debugging Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `terraform output` | Show output values | `terraform output resource_group_name` |
| `terraform show` | Show current state or plan | `terraform show tfplan` |
| `terraform graph` | Generate dependency graph | `terraform graph \| dot -Tpng > graph.png` |
| `terraform console` | Interactive console for expressions | `terraform console` |
| `terraform providers` | Show provider requirements | `terraform providers` |
| `terraform version` | Show Terraform version | `terraform version` |

### Examples

```bash
# Show all outputs
terraform output

# Show specific output
terraform output resource_group_shared_common_id

# Show current state in human-readable format
terraform show

# Show saved plan
terraform show tfplan

# Generate visual dependency graph (requires graphviz)
terraform graph | dot -Tpng > graph.png

# Interactive console to test expressions
terraform console
# Then try: var.org_name, azurecaf_name.rg_shared.result, etc.

# Show providers and versions
terraform providers

# Show Terraform version
terraform version
```

---

## Workspace Management Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `terraform workspace list` | List workspaces | `terraform workspace list` |
| `terraform workspace new` | Create new workspace | `terraform workspace new dev` |
| `terraform workspace select` | Switch workspace | `terraform workspace select prod` |
| `terraform workspace show` | Show current workspace | `terraform workspace show` |
| `terraform workspace delete` | Delete workspace | `terraform workspace delete old` |

### Examples

```bash
# List all workspaces (* indicates current)
terraform workspace list

# Create new workspace
terraform workspace new dev

# Switch to different workspace
terraform workspace select prod

# Show current workspace
terraform workspace show

# Delete workspace (must not be current workspace)
terraform workspace delete old
```

---

## Advanced Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `terraform refresh` | Update state with real infrastructure | `terraform refresh` |
| `terraform taint` | Mark resource for recreation | `terraform taint azurerm_virtual_machine.vm` |
| `terraform untaint` | Remove taint from resource | `terraform untaint azurerm_virtual_machine.vm` |
| `terraform force-unlock` | Manually unlock state | `terraform force-unlock LOCK_ID` |
| `terraform get` | Download/update modules | `terraform get -update` |

### Examples

```bash
# Refresh state to match real infrastructure
terraform refresh

# Mark resource for recreation on next apply
terraform taint azurerm_resource_group.shared_common

# Remove taint
terraform untaint azurerm_resource_group.shared_common

# Unlock state if it's stuck (use with caution!)
terraform force-unlock 1a2b3c4d-5e6f-7g8h-9i0j-1k2l3m4n5o6p

# Download and update modules
terraform get -update
```

---

## Common Workflows

### First Time Setup

```bash
# 1. Initialize Terraform
terraform init

# 2. Validate configuration
terraform validate

# 3. Format code
terraform fmt -recursive

# 4. Preview changes
terraform plan

# 5. Apply changes
terraform apply
```

### Daily Development Workflow

```bash
# 1. Make changes to .tf files

# 2. Format code
terraform fmt

# 3. Validate syntax
terraform validate

# 4. Plan changes
terraform plan -out=tfplan

# 5. Review plan output

# 6. Apply changes
terraform apply tfplan
```

### Multi-Environment Deployment (Using .tfvars)

```bash
# Development
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan

# Staging
terraform plan -var-file="environments/stage.tfvars" -out=stage.tfplan
terraform apply stage.tfplan

# Production
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan
```

### Troubleshooting Workflow

```bash
# 1. Check what's in state
terraform state list

# 2. Show details of problematic resource
terraform state show azurerm_resource_group.example

# 3. Refresh state from Azure
terraform refresh

# 4. Plan to see drift
terraform plan

# 5. If resource is broken, taint it
terraform taint azurerm_resource_group.example

# 6. Apply to recreate
terraform apply
```

### Importing Existing Resources

```bash
# 1. Add resource to .tf file (without creating it)
# resource "azurerm_resource_group" "existing" {
#   name     = "existing-rg"
#   location = "eastus"
# }

# 2. Import the existing resource
terraform import azurerm_resource_group.existing /subscriptions/SUB_ID/resourceGroups/existing-rg

# 3. Verify import
terraform state show azurerm_resource_group.existing

# 4. Run plan to check alignment
terraform plan
```

### Clean Up Workflow

```bash
# 1. Preview destruction
terraform plan -destroy

# 2. Destroy specific resource
terraform destroy -target=azurerm_resource_group.temporary

# 3. Destroy everything (careful!)
terraform destroy

# 4. Confirm with: yes
```

---

## Useful Flags and Options

### Common Flags Across Commands

| Flag | Purpose | Example |
|------|---------|---------|
| `-var="key=value"` | Set variable value | `terraform apply -var="environment=dev"` |
| `-var-file="filename"` | Load variables from file | `terraform plan -var-file="environments/prod.tfvars"` |
| `-target=resource` | Target specific resource | `terraform apply -target=azurerm_resource_group.example` |
| `-out=filename` | Save plan to file | `terraform plan -out=tfplan` |
| `-auto-approve` | Skip interactive approval | `terraform apply -auto-approve` |
| `-lock=false` | Disable state locking | `terraform apply -lock=false` |
| `-json` | Output in JSON format | `terraform show -json` |
| `-no-color` | Disable colored output | `terraform plan -no-color` |

### Plan-Specific Flags

```bash
# Destroy plan
terraform plan -destroy

# Refresh state during plan
terraform plan -refresh=true

# Skip refresh during plan
terraform plan -refresh=false

# Detailed exit code (0=success, 1=error, 2=success with changes)
terraform plan -detailed-exitcode
```

### Apply-Specific Flags

```bash
# Skip interactive approval
terraform apply -auto-approve

# Apply without refreshing state first
terraform apply -refresh=false

# Parallel resource operations (default is 10)
terraform apply -parallelism=5
```

---

## Project-Specific Commands for A10 Corp

### Working with This Repository

```bash
# Development deployment
cd /home/wsladmin/dev/pyProjects/devops/A10_Corp/basic_setup/terraform
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Production deployment
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan

# Check what was created
terraform state list
terraform output

# View specific resource
terraform state show azurerm_management_group.a10corp
terraform state show azurerm_resource_group.shared_common
```

### Verify Naming Convention Output

```bash
# Use console to test naming
terraform console

# Try these expressions:
azurecaf_name.rg_shared.result
azurecaf_name.rg_sales.result
azurecaf_name.mg_root.result
var.environment
var.org_name
```

---

## Environment Variables

Terraform recognizes these environment variables:

| Variable | Purpose | Example |
|----------|---------|---------|
| `TF_VAR_name` | Set input variable | `export TF_VAR_environment=prod` |
| `TF_LOG` | Enable logging | `export TF_LOG=DEBUG` |
| `TF_LOG_PATH` | Log file location | `export TF_LOG_PATH=./terraform.log` |
| `TF_INPUT` | Disable prompts | `export TF_INPUT=0` |
| `TF_CLI_ARGS` | Default CLI arguments | `export TF_CLI_ARGS="-no-color"` |

### Examples

```bash
# Set variable via environment
export TF_VAR_environment=dev
terraform plan  # Uses dev environment

# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply

# Disable interactive prompts
export TF_INPUT=0
terraform apply
```

---

## Best Practices

1. **Always run `terraform plan` before `apply`**
   ```bash
   terraform plan -out=tfplan
   # Review the plan carefully
   terraform apply tfplan
   ```

2. **Use `-out` flag to save plans**
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

3. **Never edit state files directly**
   ```bash
   # ❌ Don't do this
   vim terraform.tfstate

   # ✅ Use state commands instead
   terraform state rm resource.name
   ```

4. **Format code before committing**
   ```bash
   terraform fmt -recursive
   git add .
   git commit -m "Update infrastructure"
   ```

5. **Use `.tfvars` files for different environments**
   ```bash
   terraform plan -var-file="environments/prod.tfvars"
   ```

6. **Lock state files in team environments**
   - Use remote backends (Azure Storage, S3, Terraform Cloud)
   - Never disable locking in production

7. **Use `-target` sparingly**
   - Only for troubleshooting or specific scenarios
   - Prefer full plan/apply for consistency

---

## Quick Reference Cheat Sheet

```bash
# Initialization
terraform init                    # Initialize directory
terraform init -upgrade           # Upgrade providers

# Planning
terraform plan                    # Preview changes
terraform plan -out=tfplan        # Save plan
terraform plan -destroy           # Preview destruction

# Applying
terraform apply                   # Apply changes
terraform apply tfplan            # Apply saved plan
terraform apply -auto-approve     # Skip confirmation

# State
terraform state list              # List resources
terraform state show <resource>   # Show resource details
terraform state rm <resource>     # Remove from state

# Information
terraform output                  # Show outputs
terraform show                    # Show state/plan
terraform version                 # Show version

# Cleanup
terraform destroy                 # Destroy all resources

# Formatting
terraform fmt                     # Format current directory
terraform fmt -recursive          # Format recursively
terraform validate                # Validate syntax
```

---

## Additional Resources

- [Terraform CLI Documentation](https://developer.hashicorp.com/terraform/cli)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
