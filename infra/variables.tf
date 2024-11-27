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
  default     = "97b93c54-800f-452a-bd42-b8b664dce6a9"
  description = "The subscription id"
}

variable "tenant_id" {
  type        = string
  default     = "4a03f7a8-7d15-4104-83fd-94b3dd96d336"
  description = "The tenant id"
}

variable "admin_object_id" {
  type        = string
  default     = "6be7d7c2-f803-4457-b0de-97b990e02077"
  description = "TODO"
}

variable "admin_object_id_2" {
  type        = string
  default     = "3eeab002-d526-41b6-a30b-47a8ee40127b"
  description = "TODO"
}

variable "keyvault_name" {
  type        = string
  default     = "rd-keyvalt-123456789-10"
  description = "TODO"
}