variable "rg_details" {
  description = "Details for each resource group to create."
  type = map(object({
    rg_name  = string
    location = string
    tags     = optional(map(string), {})
  }))
}

variable "stg_details" {
  description = "Storage accounts to create."
  type = map(object({
    stg_name                 = string
    resource_group_name      = string
    location                 = string
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")
    account_kind             = optional(string, "StorageV2")
    tags                     = optional(map(string), {})
  }))
}
