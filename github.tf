resource "github_repository" "dorkly_repo" {
  name        = "dorkly-flags-${var.project_name}"
  description = var.github_repo_description
  visibility  = var.github_repo_private ? "private" : "public"
  auto_init   = true
}

resource "github_actions_variable" "aws_region" {
  repository    = github_repository.dorkly_repo.name
  variable_name = "AWS_REGION"
  value         = data.aws_region.current.name
}

resource "github_actions_variable" "aws_s3_bucket" {
  repository    = github_repository.dorkly_repo.name
  variable_name = "AWS_S3_BUCKET"
  value         = aws_s3_bucket.dorkly_bucket.bucket
}

resource "github_actions_variable" "dorkly_version" {
  repository    = github_repository.dorkly_repo.name
  variable_name = "DORKLY_VERSION"
  value         = var.dorkly_version
}

resource "github_actions_secret" "aws_access_key_id" {
  repository      = github_repository.dorkly_repo.name
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = aws_iam_access_key.dorkly_write_user_access_key.id
}

resource "github_actions_secret" "aws_secret_key_secret" {
  repository      = github_repository.dorkly_repo.name
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = aws_iam_access_key.dorkly_write_user_access_key.secret
}

# Upload each file to the repo using the same relative path from 'githubFiles/'
resource "github_repository_file" "dorkly_flags_project" {
  for_each            = fileset("${path.module}/githubFiles", "**")
  repository          = github_repository.dorkly_repo.name
  branch              = "main"
  file                = each.key
  content             = file("${path.module}/githubFiles/${each.key}")
  commit_message      = "Managed by Terraform"
  overwrite_on_create = true
}


