# Environment-Specific Configuration

This directory contains environment-specific variable files for Terraform deployments.

## Usage

To deploy to a specific environment, use the `-var-file` flag:

```bash
# Deploy to Development
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Deploy to Staging
terraform plan -var-file="environments/stage.tfvars"
terraform apply -var-file="environments/stage.tfvars"

# Deploy to Production
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

## Environment Files

- **dev.tfvars** - Development environment configuration
- **stage.tfvars** - Staging environment configuration
- **prod.tfvars** - Production environment configuration

## What Gets Created

Each environment will create resource groups with environment-specific names:

### Development (dev.tfvars)
- `rg-a10corp-shared-common-dev`
- `rg-a10corp-sales-dev`
- `rg-a10corp-service-dev`

### Staging (stage.tfvars)
- `rg-a10corp-shared-common-stage`
- `rg-a10corp-sales-stage`
- `rg-a10corp-service-stage`

### Production (prod.tfvars)
- `rg-a10corp-shared-common-prod`
- `rg-a10corp-sales-prod`
- `rg-a10corp-service-prod`

## Best Practices

1. **Never commit secrets** - These files contain subscription IDs which are safe, but never add passwords or keys
2. **Review before apply** - Always run `terraform plan` first
3. **Use separate state backends** - Configure different backends for each environment in CI/CD
4. **Test in dev first** - Always test changes in dev before promoting to stage/prod
