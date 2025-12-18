# Import blocks for existing Azure resources
# These resources were created manually or exist pre-Terraform
# Terraform 1.5+ declarative import feature

# IMPORTANT: This file is for IMPORTING existing resources only
# For fresh deployments (clean slate), comment out or delete import blocks below
# Import blocks use specific resource IDs that won't exist after destroy

# Uncomment ONLY if you have existing subscription associations to import:
# import {
#   to = azurerm_management_group_subscription_association.sales
#   id = "/providers/Microsoft.Management/managementGroups/b9d5cb98-ff4c-4299-86c7-86e14cf588c8/subscriptions/385c6fcb-c70b-4aed-b745-76bd608303d7"
# }

# What EXISTS and doesn't need import (pre-existing Azure resources):
# - Tenant Root Management Group (8116fad0-5032-463e-b911-cc6d1d75001d)
# - Subscription: sub-root-tenant (fdb297a9-2ece-469c-808d-a8227259f6e8)
# - Subscription: sub-a10corp-sales (385c6fcb-c70b-4aed-b745-76bd608303d7)

# What Terraform CREATES from scratch:
# - Management Groups: mg-a10corp, mg-a10corp-sales, mg-a10corp-service
# - Subscription Associations (linking subscriptions to management groups)
# - Resource Groups (per environment)

# Note: Subscriptions themselves are NOT managed by Terraform
# Only their associations to management groups are managed
