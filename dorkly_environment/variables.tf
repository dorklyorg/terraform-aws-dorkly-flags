variable "project_name" {
  type        = string
  description = "Name of the project. This will be used in various aws resource names so keep it short and sweet."
}

variable "ld_sdk_endpoint" {
  type        = string
  description = "The LaunchDarkly SDK endpoint to connect to. Used to populate readme templates"
}

variable "env" {
  type = object({
    name        = string
    description = string
  })
}

variable "github_repo" {
  type        = string
  description = "The name of the github repo that will be used to store the files created by this module."
}

variable "aws_tags" {
  type        = map(string)
  description = "Tags to apply to all AWS resources created by this module."
  default     = {}
}