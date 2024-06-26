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

module "dorkly_environment" {
  for_each        = var.environments
  source          = "./dorkly_environment"
  project_name    = var.project_name
  env             = each.value
  github_repo     = github_repository.dorkly_repo.name
  ld_sdk_endpoint = aws_lightsail_container_service.dorkly.url
}