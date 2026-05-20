# Shared partial backend configuration for all dev components.
# Created out-of-band by ../../bootstrap/bootstrap-state-backend.sh (ADR-0007).
# Each component supplies its own `key` in its backend.tf.
resource_group_name  = "rg-pep-tfstate-dev"
storage_account_name = "stpeptfstatedevldc"
container_name       = "tfstate"
use_azuread_auth     = true
