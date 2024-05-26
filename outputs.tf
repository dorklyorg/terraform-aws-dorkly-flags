output "ld_sdk_endpoint" {
  value = aws_lightsail_container_service.dorkly.url
}

output "github_repo_html_url" {
  value = github_repository.dorkly_repo.html_url
}

output "github_repo_git_clone_url" {
  value = github_repository.dorkly_repo.git_clone_url
}

output "environments" {
  value = module.dorkly_environment
}

# These shouldn't be needed for daily use but can be helpful when troubleshooting:
output "aws_s3_bucket_name" {
  value = aws_s3_bucket.dorkly_bucket.bucket
}

output "aws_sqs_queue_url" {
  value = aws_sqs_queue.dorkly_queue.url
}

output "aws_lightsail_container_service_name" {
  value = aws_lightsail_container_service.dorkly.name
}
