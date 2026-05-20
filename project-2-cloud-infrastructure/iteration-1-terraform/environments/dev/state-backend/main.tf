# ============================================================================
# Local computed values
# ============================================================================
locals {
  resource_group_name = "rg-${var.name_prefix}-tfstate-${var.environment}"

  # Deterministic, globally unique, 3-24 lowercase alphanumeric chars.
  # MUST match the literal storage_account_name in backend.tf.
  storage_account_name = lower(
    "st${var.name_prefix}tfstate${var.environment}${var.name_suffix}"
  )

  common_tags = merge(var.tags, {
    Environment = var.environment
  })
}

# ============================================================================
# Current AAD identity (the user running `terraform apply` on the work PC)
# ============================================================================
data "azurerm_client_config" "current" {}

# ============================================================================
# Resource Group — isolated from all other infrastructure
# ============================================================================
resource "azurerm_resource_group" "tfstate" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ============================================================================
# Storage Account — Terraform state backend
# Native azurerm resource (NOT AVM) — see ADR-0007 for rationale.
# ============================================================================
resource "azurerm_storage_account" "tfstate" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.tfstate.name
  location            = azurerm_resource_group.tfstate.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  shared_access_key_enabled       = true
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = false

    delete_retention_policy {
      days = var.soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  tags = local.common_tags
}

# ============================================================================
# Blob container holding the state files (one blob per component)
# ============================================================================
resource "azurerm_storage_container" "tfstate" {
  name                  = var.state_container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# ============================================================================
# RBAC — grant the current AAD identity rights to read/write state blobs.
# Required because the backend uses use_azuread_auth = true.
# ============================================================================
resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id

  description = "Allows the current AAD identity to read/write Terraform state blobs"
}

# ============================================================================
# Optional resource lock — protects the state RG from accidental deletion
# ============================================================================
resource "azurerm_management_lock" "tfstate" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "tfstate-cannot-delete"
  scope      = azurerm_resource_group.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Protects Terraform state backend from accidental deletion"
}
