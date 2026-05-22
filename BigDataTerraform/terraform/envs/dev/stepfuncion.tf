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
    Comment = "Pipeline Calidad Aire Bronze Silver Gold"
    StartAt = "BronzeToSilver"
    States = {
      BronzeToSilver = {
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

      SilverToGold = {
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

      PipelineFailed = {
        Type  = "Fail"
        Cause = "Glue Job Failed"
        Error = "PipelineExecutionError"
      }
    }
  })

  tags = var.tags
}