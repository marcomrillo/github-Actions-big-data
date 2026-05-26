# =================================================================
# PROVIDER & BACKEND CONFIGURATION
# =================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# =================================================================
# INFRASTRUCTURE MODULES (BUCKETS) - CORREGIDO
# =================================================================
module "raw_bucket" {
  source     = "../../modules/s3_lake"
  project    = var.project
  env        = var.env
  account_id = data.aws_caller_identity.current.account_id
  tags       = var.tags
}

module "staging_bucket" {
  source     = "../../modules/s3_lake"
  project    = var.project
  env        = var.env
  account_id = data.aws_caller_identity.current.account_id
  tags       = var.tags
}

module "analytics_bucket" {
  source     = "../../modules/s3_lake"
  project    = var.project
  env        = var.env
  account_id = data.aws_caller_identity.current.account_id
  tags       = var.tags
}

# =================================================================
# SECURITY MODULE (IAM) - CORREGIDO
# =================================================================
module "iam" {
  source           = "../../modules/iam"
  project          = var.project
  env              = var.env
  raw_bucket       = module.raw_bucket.bucket_name
  staging_bucket   = module.staging_bucket.bucket_name   # ◄── Soluciona el error de "staging_bucket is required"
  analytics_bucket = module.analytics_bucket.bucket_name
  temp_bucket      = module.raw_bucket.bucket_name
}

# =================================================================
# COMPUTE MODULE (GLUE JOBS)
# =================================================================
module "glue_jobs" {
  source = "../../modules/glue"

  project       = var.project
  env           = var.env
  glue_role_arn = module.iam.glue_role_arn

  raw_bucket     = module.raw_bucket.bucket_name
  staging_bucket = module.staging_bucket.bucket_name
  temp_bucket    = module.raw_bucket.bucket_name

  # Argumento genérico que hereda tu variables.tf de Glue para pasar el Init
  script_location = "s3://${module.raw_bucket.bucket_name}/scripts/bronze_to_silver.py"

  tags = var.tags
}