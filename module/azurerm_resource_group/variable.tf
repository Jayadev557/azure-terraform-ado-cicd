variable "rg_details" {
  description = "Details for each resource group to create."
  type = map(object({
    rg_name  = string
    location = string
    tags     = optional(map(string), {})
  }))
}
