variable "resource_group_location" {
  type        = string
  default     = "North Europe"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type        = string
  default     = "RD_IAC"
  description = "Resource groupe name"
}

variable "subscription_id" {
  type        = string
}

variable "tenant_id" {
  type        = string
}

variable "admin_object_id" {
  type        = string
}

variable "terraform_account_object_id" {
  type        = string
}

variable "keyvault_name" {
  type        = string
  default     = "rd-keyvalt-ccdd"
}