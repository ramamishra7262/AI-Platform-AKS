locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = merge({
    environment = var.environment
    project     = var.project
    owner       = var.owner
    managed_by  = "terraform"
    created_at  = timestamp()
  }, var.additional_tags)
}
