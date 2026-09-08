rg_details = {
  rg1 = {
    rg_name  = "rg-prod-001"
    location = "Central India"
    tags = {
      environment = "prod"
      owner       = "devops-team"
    }
  }
}

stg_details = {
  stg1 = {
    stg_name                 = "stgprod001"
    resource_group_name      = "rg-prod-001"
    location                 = "Central India"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"
    tags = {
      environment = "prod"
      owner       = "devops-team"
    }
  }
}
