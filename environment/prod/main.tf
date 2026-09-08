module "resource_group" {
  source     = "../../module/azurerm_resource_group"
  rg_details = var.rg_details
}

module "storage_account" {
  depends_on  = [module.resource_group]
  source      = "../../module/azurerm_storage_account"
  stg_details = var.stg_details
}


