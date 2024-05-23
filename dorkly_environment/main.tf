terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

locals {
  name_prefix = "dorkly-${var.project_name}-${var.env_name}"
}

# aws resources
resource "aws_secretsmanager_secret" "dorkly_sdk_key_secret" {
  name = "${local.name_prefix}-sdk-key"
  tags = var.aws_tags
}

resource "random_password" "dorkly_sdk_key_password" {
  length           = 16
  min_special      = 16
  override_special = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  special          = true
}

resource "aws_secretsmanager_secret_version" "dorkly_sdk_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.dorkly_sdk_key_secret.id
  secret_string = "sdk-${var.env_name}-${random_password.dorkly_sdk_key_password.result}"
}

resource "aws_secretsmanager_secret" "dorkly_mobile_key_secret" {
  name = "${local.name_prefix}-mob-key"
  tags = var.aws_tags
}

resource "random_password" "dorkly_mobile_key_password" {
  length           = 16
  min_special      = 16
  override_special = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  special          = true
}

resource "aws_secretsmanager_secret_version" "dorkly_mobile_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.dorkly_mobile_key_secret.id
  secret_string = "mob-${var.env_name}-${random_password.dorkly_mobile_key_password.result}"
}

# github resources
resource "github_repository_file" "dorkly_flags_project" {
  for_each            = fileset("${path.module}/exampleFlags", "**")
  repository          = var.github_repo
  file                = "project/environments/${var.env_name}/${each.key}"
  content             = file("${path.module}/exampleFlags/${each.key}")
  commit_message      = "Managed by Terraform"
  overwrite_on_create = true
}
