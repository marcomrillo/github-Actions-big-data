resource "aws_s3_bucket" "this" {
  # El nombre completo ya viene construido desde el módulo que lo invoca
  # (p. ej. "datalake-dev-raw-747554529794"). No volver a anteponer prefijos.
  bucket = var.bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "transition-old-data"
    status = "Enabled"

    # Requerido por el provider AWS v6: filtro vacío = aplica a todo el bucket
    filter {}

    transition {
      days          = 180
      storage_class = "STANDARD_IA"
    }
  }
}