resource "azurerm_resource_group" "rgblock" {
  for_each = var.rg_details
  name     = each.value.rg_name
  location = each.value.location
  tags     = each.value.tags
}
