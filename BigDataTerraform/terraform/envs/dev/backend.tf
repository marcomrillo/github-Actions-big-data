terraform {
  backend "s3" {
    bucket = "datalake-terraform-state-747554529794"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"

    encrypt = true
    # Bloqueo nativo de S3 (Terraform >= 1.10). No requiere DynamoDB.
    use_lockfile = true
  }
}
