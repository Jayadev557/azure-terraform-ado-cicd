rg_details = {
  rg1 = {
    rg_name  = "rg-preprod-001"
    location = "Central India"
    tags = {
      environment = "preprod"
      owner       = "devops-team"
    }
  }
}

stg_details = {
  stg1 = {
    stg_name                 = "stgpreprod002"
    resource_group_name      = "rg-preprod-001"
    location                 = "Central India"
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"
    tags = {
      environment = "preprod"
      owner       = "devops-team"
    }
  }
}
