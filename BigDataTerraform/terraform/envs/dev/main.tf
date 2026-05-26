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

# --- Lo que faltaba: Presentamos el data source ---
data "aws_caller_identity" "current" {}
# --------------------------------------------------

# INFRASTRUCTURE MODULES (BUCKETS)
module "raw_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  account_id  = data.aws_caller_identity.current.account_id
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

# MODULE IAM
module "iam" {
  source           = "../../modules/iam"
  project          = var.project
  env              = var.env
  raw_bucket       = module.raw_bucket.bucket_name
  staging_bucket   = module.staging_bucket.bucket_name
  analytics_bucket = module.analytics_bucket.bucket_name
  temp_bucket      = module.raw_bucket.bucket_name
}

# MODULE GLUE
module "glue_jobs" {
  source = "../../modules/glue"

  project         = var.project
  env             = var.env
  glue_role_arn   = module.iam.glue_role_arn
  
  raw_bucket      = module.raw_bucket.bucket_name
  staging_bucket  = module.staging_bucket.bucket_name
  temp_bucket     = module.raw_bucket.bucket_name
  
  script_location = "s3://${module.raw_bucket.bucket_name}/scripts/bronze_to_silver.py"
  tags            = var.tags
}