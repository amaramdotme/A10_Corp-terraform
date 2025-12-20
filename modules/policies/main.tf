resource "azurerm_management_group_policy_assignment" "tagging" {
  name                 = "enforce-env-tag"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  management_group_id  = var.management_group_id
  description          = "Enforces existence of the Environment tag on Resource Groups"
  display_name         = "Enforce Environment Tag"

  parameters = <<PARAMETERS
{
  "tagName": {
    "value": "Environment"
  }
}
PARAMETERS
}

resource "azurerm_management_group_policy_assignment" "location" {
  name                 = "allowed-locations"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  management_group_id  = var.management_group_id
  description          = "Restrict resource deployment to specific regions"
  display_name         = "Allowed Locations"

  parameters = <<PARAMETERS
{
  "listOfAllowedLocations": {
    "value": ["${var.location}"]
  }
}
PARAMETERS
}

resource "azurerm_management_group_policy_assignment" "vm_skus" {
  name                 = "allowed-vm-skus"
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3"
  management_group_id  = var.management_group_id
  description          = "Limits Virtual Machine SKUs to approved cost-effective sizes"
  display_name         = "Allowed Virtual Machine Size SKUs"

  parameters = <<PARAMETERS
{
  "listOfAllowedSkus": {
    "value": [${join(",", formatlist("\"%s\"", var.allowed_vm_skus))}]
  }
}
PARAMETERS
}

# Lookup the policy by display name to ensure we get the correct ID
data "azurerm_policy_definition" "secure_transfer" {
  display_name = "Secure transfer to storage accounts should be enabled"
}

resource "azurerm_management_group_policy_assignment" "secure_transfer" {
  name                 = "secure-transfer"
  policy_definition_id = data.azurerm_policy_definition.secure_transfer.id
  management_group_id  = var.management_group_id
  description          = "Enforces HTTPS (Secure Transfer) on all Storage Accounts"
  display_name         = "Secure Transfer to Storage Accounts Enabled"
}
