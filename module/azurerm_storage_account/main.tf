resource "azurerm_storage_account" "stgblock" {
  for_each = var.stg_details

  name                     = each.value.stg_name
  resource_group_name      = each.value.resource_group_name
  location                 = each.value.location
  account_tier             = each.value.account_tier
  account_replication_type = each.value.account_replication_type
  account_kind             = each.value.account_kind

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = each.value.tags
}





# #checkov:skip=CKV2_AZURE_1:CMK is not required for this learning project
# resource "azurerm_storage_account" "stgblock" {
#   for_each = var.stg_details

#   name                     = each.value.stg_name
#   resource_group_name      = each.value.resource_group_name
#   location                 = each.value.location
#   account_tier             = each.value.account_tier
#   account_replication_type = each.value.account_replication_type
#   account_kind             = each.value.account_kind
#   tags                     = each.value.tags
# }
