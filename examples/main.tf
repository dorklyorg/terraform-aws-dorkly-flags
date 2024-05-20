terraform {
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

module "dorkly-flags-backend" {
  source = "git::git@github.com:dorklyorg/terraform-aws-dorkly-flags.git//?ref=v0.0.1"

  # or for developing locally:
  #   source = "../../terraform-aws-dorkly-flags"

  project_name = "project1"
}