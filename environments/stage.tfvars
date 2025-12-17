# Staging Environment Configuration
# Sensitive values (subscription/tenant IDs) are fetched from Azure Key Vault
# Other variables (org_name, location, common_tags) use defaults from variables.tf
# See data-sources.tf and DECISIONS.md Decision 14

environment = "stage"
