resource "aws_iam_role" "glue_role" {
  name = "${var.project}-${var.env}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Política unificada con privilegios plenos de lectura/escritura/borrado para el Data Lake
resource "aws_iam_policy" "glue_s3_policy" {
  name = "${var.project}-${var.env}-glue-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. PERMISOS CAPA BRONZE (RAW)
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.raw_bucket}",
          "arn:aws:s3:::${var.raw_bucket}/*"
        ]
      },
      # 2. PERMISOS CAPA SILVER (STAGING) - Soporta lectura para el Job 3 y borrados de Spark
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.staging_bucket}",
          "arn:aws:s3:::${var.staging_bucket}/*"
        ]
      },
      # 3. PERMISOS CAPA GOLD (ANALYTICS) - Permite la persistencia del Datamart final
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.analytics_bucket}",
          "arn:aws:s3:::${var.analytics_bucket}/*"
        ]
      },
      # 4. PERMISOS TEMPORALES (SCRATCH SPACE)
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.temp_bucket}",
          "arn:aws:s3:::${var.temp_bucket}/*"
        ]
      }
    ]
  })
}

# Attach de políticas
resource "aws_iam_role_policy_attachment" "glue_s3_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}