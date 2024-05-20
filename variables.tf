# Required vars
variable "project_name" {
  type        = string
  description = "Brief name of your project that will utilize feature flags. AWS resources will use this and the github repo's name will be based on this value: dorkly-flags-<project_name>"
}

# Optional vars:
variable "aws_lightsail_container_power" {
  type        = string
  description = "The power of the lightsail container service. Options are nano, micro, small, medium, large, xlarge"
  default     = "nano"
}

variable "dorkly_docker_image_tag" {
  type        = string
  default     = "latest"
  description = "The docker image tag to use for the dorkly service"
}

variable "github_repo_description" {
  type        = string
  description = "The description of the project that will utilize feature flags. This will be used as the description of the github repository"
  default     = "Dorkly Feature Flags for your project"
}

variable "github_repo_private" {
  type        = bool
  description = "Whether the github repository should be private or public. You probably want this to be private"
  default     = true
}

