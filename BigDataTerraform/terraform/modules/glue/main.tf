locals {
  # El workflow sube los 3 scripts a s3://<raw>/scripts/
  scripts_base = "s3://${var.raw_bucket}/scripts"

  # Rutas de datos de la arquitectura Medallion
  input_json  = "s3://${var.raw_bucket}/Datos_SIATA_Aire_pm25_reducido.json"
  silver_path = "s3://${var.staging_bucket}/aire_pm25/"
  gold_path   = "s3://${var.analytics_bucket}/aire_pm25_gold/"
  temp_dir    = "s3://${var.temp_bucket}/temp/"
}

# ─── PASO 0: VALIDACIÓN DE CALIDAD (Great Expectations) ───
resource "aws_glue_job" "data_quality" {
  name     = "${var.project}-${var.env}-data-quality"
  role_arn = var.glue_role_arn

  command {
    script_location = "${local.scripts_base}/validate_expectations.py"
    python_version  = "3"
  }

  default_arguments = {
    "--input_path" = local.input_json
    "--TempDir"    = local.temp_dir
    # validate_expectations.py importa great_expectations; se instala en runtime.
    # Pin <1.0 porque el script usa la API fluida context.sources.add_spark.
    "--additional-python-modules" = "great_expectations==0.18.19"
  }

  worker_type       = "G.1X"
  number_of_workers = 2
  glue_version      = "5.0"
  timeout           = 10

  tags = var.tags
}

# ─── PASO 1: BRONZE → SILVER ───
resource "aws_glue_job" "sales_etl" {
  name     = "${var.project}-${var.env}-bronze-to-silver"
  role_arn = var.glue_role_arn

  command {
    script_location = "${local.scripts_base}/bronze_to_silver.py"
    python_version  = "3"
  }

  default_arguments = {
    "--input_path"  = local.input_json
    "--output_path" = local.silver_path
    "--TempDir"     = local.temp_dir
  }

  worker_type       = "G.1X"
  number_of_workers = 2
  glue_version      = "5.0"
  timeout           = 10

  tags = var.tags
}

# ─── PASO 2: SILVER → GOLD ───
resource "aws_glue_job" "silver_to_gold" {
  name     = "${var.project}-${var.env}-silver-to-gold"
  role_arn = var.glue_role_arn

  command {
    script_location = "${local.scripts_base}/silver_to_gold.py"
    python_version  = "3"
  }

  default_arguments = {
    "--silver_path" = local.silver_path
    "--gold_path"   = local.gold_path
    "--TempDir"     = local.temp_dir
  }

  worker_type       = "G.1X"
  number_of_workers = 2
  glue_version      = "5.0"
  timeout           = 10

  tags = var.tags
}