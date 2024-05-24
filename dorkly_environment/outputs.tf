output "aws_secrets_manager_secret_dorkly_sdk_key_secret_arn" {
  value = aws_secretsmanager_secret.dorkly_sdk_key_secret.arn
}

output "aws_secrets_manager_secret_dorkly_sdk_key_secret_name" {
  value = aws_secretsmanager_secret.dorkly_sdk_key_secret.name
}

output "aws_secrets_manager_secret_dorkly_sdk_key_secret_value" {
  value = aws_secretsmanager_secret_version.dorkly_sdk_key_secret_version.secret_string
}

output "aws_secrets_manager_secret_dorkly_mobile_key_secret_arn" {
  value = aws_secretsmanager_secret.dorkly_mobile_key_secret.arn
}

output "aws_secrets_manager_secret_dorkly_mobile_key_secret_name" {
  value = aws_secretsmanager_secret.dorkly_mobile_key_secret.name
}

output "aws_secrets_manager_secret_dorkly_mobile_key_secret_value" {
  value = aws_secretsmanager_secret_version.dorkly_mobile_key_secret_version.secret_string
}


