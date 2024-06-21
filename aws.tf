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
      S3_BUCKET = aws_s3_bucket.dorkly_bucket.bucket
      LOG_LEVEL = var.ld_relay_log_level

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

# S3 Bucket
resource "aws_s3_bucket" "dorkly_bucket" {
  bucket = local.name
  tags   = local.tags
}

# IAM User for reading S3 bucket
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
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = [
          "${aws_s3_bucket.dorkly_bucket.arn}/*",
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
    Version = "2012-10-17"
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
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        "Resource" : concat(
          [for e in module.dorkly_environment : e.env.aws_secret_sdk_key_arn],
          [for e in module.dorkly_environment : e.env.aws_secret_mobile_key_arn],
        )
      },
      {
        "Effect" : "Allow",
        "Action" : "secretsmanager:ListSecrets",
        "Resource" : "*"
      }
    ]
  })
}