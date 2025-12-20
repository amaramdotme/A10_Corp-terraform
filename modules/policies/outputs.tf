output "assignment_ids" {
  description = "IDs of the Policy Assignments"
  value = {
    tagging         = azurerm_management_group_policy_assignment.tagging.id
    location        = azurerm_management_group_policy_assignment.location.id
    vm_skus         = azurerm_management_group_policy_assignment.vm_skus.id
    secure_transfer = azurerm_management_group_policy_assignment.secure_transfer.id
  }
}
