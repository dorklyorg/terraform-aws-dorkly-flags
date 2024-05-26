locals {
  tf_yaml_comment = "# Managed by Terraform! Do not edit. Any changed made by humans will be overwritten."
}

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

resource "github_repository_file" "dorkly_flags_project_yml" {
  repository          = github_repository.dorkly_repo.name
  file                = "project/project.yml"
  content             = <<-EOF
                        ${local.tf_yaml_comment}
                        name: ${var.project_name}
                        description: ${var.project_description}
                        EOF
  commit_message      = "Managed by Terraform"
  overwrite_on_create = true
}

# Upload each file to the repo using the same relative path from 'githubFiles/'
resource "github_repository_file" "dorkly_flags_files" {
  for_each            = fileset("${path.module}/githubFiles", "**")
  repository          = github_repository.dorkly_repo.name
  file                = each.key
  content             = file("${path.module}/githubFiles/${each.key}")
  commit_message      = "Managed by Terraform"
  overwrite_on_create = true
}

resource "github_repository_file" "dorkly_flags_readme" {
  for_each = var.environments

  repository          = github_repository.dorkly_repo.name
  file                = "project/environments/${each.key}/readme.md"
  content             = <<EOF
# Dorkly Flags for project: ${var.project_name} environment: ${each.key}
### This file is managed by terraform. Do not edit manually.

Dorkly endpoint for this environment: `${aws_lightsail_container_service.dorkly.url}`

## Quick Start: Configuring an SDK
Check out the LaunchDarkly [hello-go example](https://github.com/launchdarkly/hello-go) and modify the config as follows:

```golang
    dorklyConfig := ld.Config{
		ServiceEndpoints: ldcomponents.RelayProxyEndpoints("${aws_lightsail_container_service.dorkly.url}"),
		Events:           ldcomponents.NoEvents(),
	}

	ldClient, err := ld.MakeCustomClient("${module.dorkly_environment[each.key].env.aws_secret_sdk_key_value}", dorklyConfig, 10*time.Second)
```

## Other handy bits
### SDK Key
* SDK Key value: `${module.dorkly_environment[each.key].env.aws_secret_sdk_key_value}`
* AWS secret arn: `${module.dorkly_environment[each.key].env.aws_secret_sdk_key_arn}`
* AWS secret name: `${module.dorkly_environment[each.key].env.aws_secret_sdk_key_name}`
* AWS: Get secret via cli: `aws secretsmanager get-secret-value --secret-id ${module.dorkly_environment[each.key].env.aws_secret_sdk_key_name}  | jq -r .SecretString
* Terraform: Inject secret for use in your deployed service:

### Mobile Key
* Mobile Key value: `${module.dorkly_environment[each.key].env.aws_secret_mobile_key_value}`
* Aws secret arn: `${module.dorkly_environment[each.key].env.aws_secret_mobile_key_arn}`
* Aws secret name: `${module.dorkly_environment[each.key].env.aws_secret_mobile_key_name}`
* Get secret using aws cli: `aws secretsmanager get-secret-value --secret-id ${module.dorkly_environment[each.key].env.aws_secret_mobile_key_name}  | jq -r .SecretString
EOF
  commit_message      = "Managed by Terraform"
  overwrite_on_create = true
}


