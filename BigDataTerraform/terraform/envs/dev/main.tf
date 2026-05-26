terraform {
  backend "s3" {
    bucket         = "datalake-terraform-state-747554529794"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# Obtiene de forma dinámica el ID de tu cuenta de AWS (747554529794)
data "aws_caller_identity" "current" {}

# ==========================================
# 1. CAPAS DEL DATA LAKE (S3 BUCKETS)
# ==========================================

module "raw_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  bucket_name = "bronze"
  account_id  = data.aws_caller_identity.current.account_id
  tags        = var.tags
}

module "staging_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  bucket_name = "silver"
  account_id  = data.aws_caller_identity.current.account_id
  tags        = var.tags
}

module "analytics_bucket" {
  source      = "../../modules/s3_lake"
  project     = var.project
  env         = var.env
  bucket_name = "gold"
  account_id  = data.aws_caller_identity.current.account_id
  tags        = var.tags
}

# ==========================================
# 2. SEGURIDAD Y ROLES DE ACCESO (IAM)
# ==========================================

module "iam" {
  source = "../../modules/iam"

  project = var.project
  env     = var.env

  # Le otorgamos permisos al rol sobre las tres capas reales del Data Lake
  raw_bucket       = module.raw_bucket.bucket_name
  staging_bucket   = module.staging_bucket.bucket_name
  analytics_bucket = module.analytics_bucket.bucket_name
}

# ==========================================
# 3. PROCESAMIENTO DE DATOS (AWS GLUE JOBS)
# ==========================================

module "glue_jobs" {
  source = "../../modules/glue"

  project = var.project
  env     = var.env

  glue_role_arn = module.iam.glue_role_arn

  # Buckets de Origen y Destino
  raw_bucket       = module.raw_bucket.bucket_name
  staging_bucket   = module.staging_bucket.bucket_name
  analytics_bucket = module.analytics_bucket.bucket_name

  # Rutas de ejecución de los scripts renombrados y corregidos
  script_quality_location = "s3://${module.raw_bucket.bucket_name}/scripts/validate_expectations.py"
  script_etl_location     = "s3://${module.raw_bucket.bucket_name}/scripts/etl_air_quality.py"

  tags = var.tags
}

# ==========================================
# 4. ORQUESTACIÓN DE PIPELINE (STEP FUNCTIONS)
# ==========================================

module "step_functions" {
  source = "../../modules/step_functions"

  project = var.project
  env     = var.env

  # Roles de IAM requeridos para ejecutar máquinas de estado
  step_function_role_arn = module.iam.step_function_role_arn

  # Conectamos las salidas de los Glue Jobs creados para armar el flujo secuencial
  glue_job_quality_name = module.glue_jobs.glue_job_quality_name
  glue_job_etl_name     = module.glue_jobs.glue_job_etl_name

  tags = var.tags
}