## terraform-aws-dorkly-flags
Terraform module for provisiononing the Dorkly Feature Flags infrastructure on AWS and GitHub.
[More info on the Dorkly project](https://github.com/dorklyorg)
[Terraform Registry page](https://registry.terraform.io/modules/dorklyorg/dorkly-flags/aws/latest)

## Notes on using this module
### On GitHub Repo ownership
If you're wanting the owner of the Dorkly flags GitHub repo to be a user, then you can ignore this section.

If you're wanting the owner of the GitHub repo to be an organization, then you probably need to set the `GITHUB_OWNER` environment variable to the name of the organization.
The GitHub provider does have an `owner` field but it is not always honored. See https://github.com/integrations/terraform-provider-github/issues/1686#issuecomment-2119456651