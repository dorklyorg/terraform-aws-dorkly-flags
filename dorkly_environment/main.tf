terraform {
  required_version = ">= 1.8"
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
  name_prefix        = "dorkly-${var.project_name}-${var.env.name}"
  sdk_key_display    = var.env.isProduction ? "(Production environment detected. Retrieve sdk key from AWS secrets manager or terraform output)" : aws_secretsmanager_secret_version.dorkly_sdk_key_secret_version.secret_string
  mobile_key_display = var.env.isProduction ? "(Production environment detected. Retrieve mobile key from AWS secrets manager or terraform output)" : aws_secretsmanager_secret_version.dorkly_mobile_key_secret_version.secret_string
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
  secret_string = "sdk-${var.env.name}-${random_password.dorkly_sdk_key_password.result}"
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
  secret_string = "mob-${var.env.name}-${random_password.dorkly_mobile_key_password.result}"
}

# github resources
resource "github_repository_file" "dorkly_flags_project" {
  for_each            = fileset("${path.module}/exampleFlags", "**")
  repository          = var.github_repo
  file                = "project/environments/${var.env.name}/${each.key}"
  content             = file("${path.module}/exampleFlags/${each.key}")
  commit_message      = "terraform robot: project/environments/${var.env.name}/${each.key}"
  overwrite_on_create = true
}

resource "github_repository_file" "dorkly_flags_readme" {
  repository          = var.github_repo
  file                = "project/environments/${var.env.name}/readme.md"
  content             = <<EOF
# Dorkly Flags for project: ${var.project_name} environment: ${var.env.name}
### This file is managed by terraform. Do not edit manually.

## Description for ${var.env.name} environment
${var.env.description}

## Quick Start: Configuring an SDK
Check out the LaunchDarkly [hello-go example](https://github.com/launchdarkly/hello-go) and modify the config as follows:

```golang
    dorklyConfig := ld.Config{
		ServiceEndpoints: ldcomponents.RelayProxyEndpoints("${var.ld_sdk_endpoint}"),
		Events:           ldcomponents.NoEvents(),
	}

	ldClient, err := ld.MakeCustomClient("${local.sdk_key_display}", dorklyConfig, 10*time.Second)
```

## Other handy bits
All values below and others are available as terraform outputs for easy wiring into your app.

* Endpoint for this environment: `${var.ld_sdk_endpoint}`
* client-side id: `${var.env.name}`

### SDK Key
* SDK Key value: `${local.sdk_key_display}`
* AWS secret arn: `${aws_secretsmanager_secret_version.dorkly_sdk_key_secret_version.arn}`
* AWS secret name: `${aws_secretsmanager_secret.dorkly_sdk_key_secret.name}`
* AWS: Get secret via cli: `aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.dorkly_sdk_key_secret.name}  | jq -r .SecretString`

### Mobile Key
* Mobile Key value: `${local.mobile_key_display}`
* Aws secret arn: `${aws_secretsmanager_secret_version.dorkly_mobile_key_secret_version.arn}`
* Aws secret name: `${aws_secretsmanager_secret.dorkly_mobile_key_secret.name}`
* Get secret using aws cli: `aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.dorkly_mobile_key_secret.name}  | jq -r .SecretString`

EOF
  commit_message      = "terraform robot: project/environments/${var.env.name}/readme.md"
  overwrite_on_create = true
}
