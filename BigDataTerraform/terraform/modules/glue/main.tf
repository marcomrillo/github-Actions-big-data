resource "aws_glue_job" "sales_etl" {
  name     = "${var.project}-${var.env}-bronze-to-silver"
  role_arn = var.glue_role_arn

  command {
    script_location = var.script_location
    python_version  = "3"
  }

  default_arguments = {
    "--input_path"  = "s3://${var.raw_bucket}/Datos_SIATA_Aire_pm25_reducido.json"
    "--output_path" = "s3://${var.staging_bucket}/aire_pm25/"
    "--TempDir"     = "s3://${var.temp_bucket}/temp/"
  }

  worker_type       = "G.1X"
  number_of_workers = 2

  glue_version = "5.0"

  timeout = 10

  tags = var.tags
}