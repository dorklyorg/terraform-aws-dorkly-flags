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
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "github" {
  # the owner field is not always respected when creating a new repo.
  # https://github.com/integrations/terraform-provider-github/issues/1686
  # You must set the owner via an env var: GITHUB_OWNER
  owner = "dorklyorg"
}

module "dorkly-flags-example" {
  source       = "git::git@github.com:dorklyorg/terraform-aws-dorkly-flags.git//?ref=v0.0.7"
  project_name = "example"

  # for demo purposes only. You should probably set this to true.
  github_repo_private = false
}

# You'll want to inject the outputs of this module into the Terraform code that provisions your feature-flagged apps:
# For all LaunchDarkly SDKs you'll need to provide this endpoint:
output "ld_sdk_endpoint" {
  value = module.dorkly-flags-example.ld_sdk_endpoint
}

# For server-side SDKs you'll need to provide the SDK key.
# There are 2 ways to get the SDK key in your terraform code:
#
# 1. Use the value directly from the output and inject it as an env var in your app for use by the LaunchDarkly SDK
# module.<your name for this module>.environments["<your env name>"].env.aws_secret_sdk_key_value
#
# 2. (More secure?) Grab the secret from AWS Secrets Manager using one of the following outputs:
# a. ARN: module.<your name for this module>.environments["<your env name>"].env.aws_secret_sdk_key_arn
# b. Name: module.<your name for this module>.environments["<your env name>"].env.aws_secret_sdk_key_name

output "environments" {
  value     = module.dorkly-flags-example.environments
  sensitive = true
}

# Other outputs
output "github_repo_html_url" {
  value = module.dorkly-flags-example.github_repo_html_url
}

output "github_repo_git_clone_url" {
  value = module.dorkly-flags-example.github_repo_git_clone_url
}
