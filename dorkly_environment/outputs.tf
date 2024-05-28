output "env" {
  value = tomap({
    "env_name" : var.env.name,
    "project_name" : var.project_name,
    "github_repo" : var.github_repo,

    "aws_secret_sdk_key_arn" : aws_secretsmanager_secret.dorkly_sdk_key_secret.arn,
    "aws_secret_sdk_key_name" : aws_secretsmanager_secret.dorkly_sdk_key_secret.name,
    "aws_secret_sdk_key_value" : aws_secretsmanager_secret_version.dorkly_sdk_key_secret_version.secret_string,

    "aws_secret_mobile_key_arn" : aws_secretsmanager_secret.dorkly_mobile_key_secret.arn,
    "aws_secret_mobile_key_name" : aws_secretsmanager_secret.dorkly_mobile_key_secret.name,
    "aws_secret_mobile_key_value" : aws_secretsmanager_secret_version.dorkly_mobile_key_secret_version.secret_string,

    "markdown_summary" : <<EOF
### Environment: ${var.env.name}
* [Flag configs and more info](project/environments/${var.env.name})
* Description: ${var.env.description}
* Is Production? ${var.env.isProduction}
EOF
    }
  )
}
