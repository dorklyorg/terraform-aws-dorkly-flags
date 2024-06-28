## terraform-aws-dorkly-flags development example
This example should be used when developing or debugging the module or any of its components.

Requirements:
1. AWS credentials with permissions to create S3 buckets, Lightsail containers, and IAM roles (and maybe more)
2. Github token with permissions to create repos, secrets, and actions.
3. Terraform installed on your machine.

To run the terraform you need to have both AWS and Github credentials. Here's one possible example:
```bash
AWS_PROFILE=<aws profile> \
GITHUB_TOKEN=<github token allowing repo creation etc> \
GITHUB_OWNER=<user or org> \
terraform apply
```