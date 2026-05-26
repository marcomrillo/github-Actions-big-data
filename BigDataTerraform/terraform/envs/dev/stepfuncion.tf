resource "aws_iam_role" "sfn_glue" {
  name = "${var.project}-${var.env}-sfn-glue"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "sfn_glue" {
  name = "${var.project}-${var.env}-sfn-glue-inline"
  role = aws_iam_role.sfn_glue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-${var.env}-glue-role"
      }
    ]
  })
}

resource "aws_sfn_state_machine" "sales_etl" {
  name     = "${var.project}-${var.env}-sales-etl-pipeline"
  role_arn = aws_iam_role.sfn_glue.arn

  definition = jsonencode({
    Comment = "Pipeline Calidad Aire Bronze Silver Gold con Compuerta de Gobierno GX"
    StartAt = "DataQuality_Validation"
    States = {

      # ─── NUEVO PASO INICIAL: VALIDACIÓN CON GREAT EXPECTATIONS ───
      "DataQuality_Validation" = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          # Este será el nuevo Job que añadiremos en tu archivo de Glue
          JobName = "${var.project}-${var.env}-data-quality"
        }
        Retry = [
          {
            ErrorEquals     = ["States.ALL"]
            IntervalSeconds = 30
            MaxAttempts     = 2
            BackoffRate     = 2
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "PipelineFailed"
          }
        ]
        # Si la calidad es exitosa, arranca tu flujo normal anterior
        Next = "BronzeToSilver"
      }

      # ─── TU PASO 1 ORIGINAL: BRONZE TO SILVER ───
      "BronzeToSilver" = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "${var.project}-${var.env}-bronze-to-silver"
        }
        Retry = [
          {
            ErrorEquals     = ["States.ALL"]
            IntervalSeconds = 30
            MaxAttempts     = 2
            BackoffRate     = 2
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "PipelineFailed"
          }
        ]
        Next = "SilverToGold"
      }

      # ─── TU PASO 2 ORIGINAL: SILVER TO GOLD ───
      "SilverToGold" = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "${var.project}-${var.env}-silver-to-gold"
        }
        Retry = [
          {
            ErrorEquals     = ["States.ALL"]
            IntervalSeconds = 30
            MaxAttempts     = 2
            BackoffRate     = 2
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "PipelineFailed"
          }
        ]
        End = true
      }

      # ─── TU MANEJADOR DE ERRORES ORIGINAL ───
      "PipelineFailed" = {
        Type  = "Fail"
        Cause = "Glue Job Failed"
        Error = "PipelineExecutionError"
      }
    }
  })

  tags = var.tags
}