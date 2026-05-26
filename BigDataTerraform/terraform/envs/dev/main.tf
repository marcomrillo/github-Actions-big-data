# =================================================================
# INFRASTRUCTURE MODULES (BUCKETS) - CONFIGURACIÓN ESTRICTA
# =================================================================

module "raw_bucket" {
  source      = "../../modules/s3_lake"
  # Variables requeridas por el módulo interno s3_lake
  project     = var.project
  env         = var.env
  account_id  = data.aws_caller_identity.current.account_id
  # Variable para el nombre del bucket
  bucket_name = "${var.project}-${var.env}-raw-${data.aws_caller_identity.current.account_id}"
  tags        = var.tags
}

module "staging_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = "${var.project}-${var.env}-silver-${data.aws_caller_identity.current.account_id}"
  tags        = var.tags
}

module "analytics_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = "${var.project}-${var.env}-gold-${data.aws_caller_identity.current.account_id}"
  tags        = var.tags
}