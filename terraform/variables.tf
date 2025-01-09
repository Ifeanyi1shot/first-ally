variable "location" {
  default = "East US"
}

variable "resource_group_name" {
  default = "AppResourceGroup"
}

variable "sql_password" {
  description = "The secure password for SQL admin user."
  default     = "P@ssword1234" 
}
