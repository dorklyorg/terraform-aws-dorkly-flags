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
  source                  = "../../../terraform-aws-dorkly-flags"
  dorkly_docker_image_tag = "0.0.1"
  dorkly_version          = "main"

  project_name = "project1"
}