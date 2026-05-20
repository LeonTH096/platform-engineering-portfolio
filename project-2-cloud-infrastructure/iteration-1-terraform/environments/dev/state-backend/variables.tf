variable "location" {
  description = "Azure region for state backend resources."
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Environment identifier (dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "name_prefix" {
  description = "Short prefix for resource naming (lowercase, 3-8 chars)."
  type        = string
  default     = "pep"

  validation {
    condition     = can(regex("^[a-z]{3,8}$", var.name_prefix))
    error_message = "name_prefix must be 3-8 lowercase letters."
  }
}

variable "name_suffix" {
  description = "Fixed token appended to the storage account name for global uniqueness. Pick once, never change. Company-agnostic."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,9}$", var.name_suffix))
    error_message = "name_suffix must be 2-9 lowercase letters/digits."
  }
}

variable "state_container_name" {
  description = "Name of the blob container that holds Terraform state files."
  type        = string
  default     = "tfstate"
}

variable "soft_delete_retention_days" {
  description = "Days to retain soft-deleted blobs and containers."
  type        = number
  default     = 14

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 365
    error_message = "Retention must be between 7 and 365 days."
  }
}

variable "enable_resource_lock" {
  description = "Apply a CanNotDelete lock on the state RG. Disable in dev for clean teardown."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "platform-engineering-portfolio"
    Component = "state-backend"
    ManagedBy = "Terraform"
  }
}
