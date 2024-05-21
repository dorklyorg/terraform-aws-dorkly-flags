locals {
  name = "dorkly-${var.project_name}"
  tags = {
    dorkly         = "true"
    dorkly-project = var.project_name
  }
}

data "aws_region" "current" {}

resource "aws_lightsail_container_service" "dorkly" {
  name        = local.name
  power       = var.aws_lightsail_container_power
  scale       = 1
  is_disabled = false
  tags        = local.tags
}

resource "aws_lightsail_container_service_deployment_version" "dorkly" {
  container {
    container_name = local.name
    image          = "drichelson/dorkly:${var.dorkly_docker_image_tag}"

    command = []

    environment = {
      AWS_REGION    = data.aws_region.current.name
      SQS_QUEUE_URL = aws_sqs_queue.dorkly_queue.url
      S3_URL = "s3://${aws_s3_bucket.dorkly_bucket.bucket}/flags.tar.gz"

      # TODO: can we use role permissions instead of access keys?
      AWS_ACCESS_KEY_ID     = aws_iam_access_key.dorkly_read_user_access_key.id
      AWS_SECRET_ACCESS_KEY = aws_iam_access_key.dorkly_read_user_access_key.secret
    }

    ports = {
      8030 = "HTTP"
    }
  }

  public_endpoint {
    container_name = local.name
    container_port = 8030

    health_check {
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout_seconds     = 3
      interval_seconds    = 10
      path                = "/status"
      success_codes       = "200"
    }
  }

  service_name = aws_lightsail_container_service.dorkly.name
}

# SQS Queue
resource "aws_sqs_queue" "dorkly_queue" {
  name   = local.name
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "SQS:SendMessage"
        ]
        Resource = [
          "arn:aws:sqs:*:*:${local.name}"
        ],
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.dorkly_bucket.arn
          }
        }
      }
    ]
  })
  tags = local.tags
}

# S3 Bucket
resource "aws_s3_bucket" "dorkly_bucket" {
  bucket = local.name
  tags   = local.tags
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "dorkly_bucket_notification" {
  bucket = aws_s3_bucket.dorkly_bucket.id

  queue {
    queue_arn = aws_sqs_queue.dorkly_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_sqs_queue.dorkly_queue
  ]
}

# IAM User for reading SQS queue and reading S3 bucket
resource "aws_iam_user" "dorkly_read_user" {
  name = "${local.name}-read"
  tags = local.tags
}

resource "aws_iam_access_key" "dorkly_read_user_access_key" {
  user = aws_iam_user.dorkly_read_user.name
}

resource "aws_iam_user_policy" "dorkly_read_user_policy" {
  name = "${local.name}-read-policy"
  user = aws_iam_user.dorkly_read_user.name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          "${aws_s3_bucket.dorkly_bucket.arn}/*",
          aws_sqs_queue.dorkly_queue.arn
        ]
      }
    ]
  })
}

# IAM User for writing S3 bucket
resource "aws_iam_user" "dorkly_write_user" {
  name = "${local.name}-write"
  tags = local.tags
}

resource "aws_iam_access_key" "dorkly_write_user_access_key" {
  user = aws_iam_user.dorkly_write_user.name
}

resource "aws_iam_user_policy" "dorkly_write_user_policy" {
  name = "${local.name}-write-user-policy"
  user = aws_iam_user.dorkly_write_user.name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.dorkly_bucket.arn,
          "${aws_s3_bucket.dorkly_bucket.arn}/*"
        ]
      }
    ]
  })
}