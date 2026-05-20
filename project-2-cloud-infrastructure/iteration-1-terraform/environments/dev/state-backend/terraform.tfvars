location    = "westeurope"
environment = "dev"
name_prefix = "pep"
name_suffix = "ldc" # your fixed token — makes "stpeptfstatedevldc"

soft_delete_retention_days = 14
enable_resource_lock       = false

tags = {
  Project   = "platform-engineering-portfolio"
  Component = "state-backend"
  ManagedBy = "Terraform"
  Owner     = "leonardo"
}
