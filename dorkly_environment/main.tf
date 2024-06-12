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
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

locals {
  name_prefix = "dorkly-${var.project_name}-${var.env.name}"
}

# aws resources
resource "aws_secretsmanager_secret" "dorkly_sdk_key_secret" {
  name = "${local.name_prefix}-sdk-key"
  tags = var.aws_tags
}

resource "random_password" "dorkly_sdk_key_password" {
  length           = 16
  min_special      = 16
  override_special = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  special          = true
}

resource "aws_secretsmanager_secret_version" "dorkly_sdk_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.dorkly_sdk_key_secret.id
  secret_string = "sdk-${var.env.name}-${random_password.dorkly_sdk_key_password.result}"
}

resource "aws_secretsmanager_secret" "dorkly_mobile_key_secret" {
  name = "${local.name_prefix}-mob-key"
  tags = var.aws_tags
}

resource "random_password" "dorkly_mobile_key_password" {
  length           = 16
  min_special      = 16
  override_special = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  special          = true
}

resource "aws_secretsmanager_secret_version" "dorkly_mobile_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.dorkly_mobile_key_secret.id
  secret_string = "mob-${var.env.name}-${random_password.dorkly_mobile_key_password.result}"
}

# github resources
resource "github_repository_file" "dorkly_flags_project" {
  for_each            = fileset("${path.module}/exampleFlags", "**")
  repository          = var.github_repo
  file                = "project/environments/${var.env.name}/${each.key}"
  content             = file("${path.module}/exampleFlags/${each.key}")
  commit_message      = "terraform robot: project/environments/${var.env.name}/${each.key}"
  overwrite_on_create = true
}

resource "github_repository_file" "dorkly_flags_readme" {
  repository          = var.github_repo
  file                = "project/environments/${var.env.name}/README.md"
  content             = <<EOF
# Dorkly Flags for `${var.project_name}` project, `${var.env.name}` environment

> [!WARNING]
> This file is managed by terraform. Do not edit manually.

## `${var.env.name}` environment description

> ${var.env.description}

## Quick Start

If you're reading this, your organization's Dorkly server should now be available for serving feature flags to your code.
To use those flags, ensure that:
- The correct LaunchDarkly SDK has been added to your application
- The SDK is configured to use your Dorkly server

### Adding an SDK to your application

We recommend following the [LaunchDarkly SDK documentation](https://docs.launchdarkly.com/sdk/). In particular:

1. Read [Getting started with SDKs](https://docs.launchdarkly.com/sdk/concepts/getting-started)
1. Choose the [server-side SDK](https://docs.launchdarkly.com/sdk/server-side) or [client-side SDK](https://docs.launchdarkly.com/sdk/client-side) most suitable for your application
1. Follow the instructions to install the SDK and add it to your application
1. To implement the section of the instructions entitled **Initialize the client**, you'll need a [key](https://docs.launchdarkly.com/sdk/concepts/client-side-server-side#keys). Continue to the next section.

### Use the correct key

Server-side SDKs should use this SDK Key:

```
${aws_secretsmanager_secret_version.dorkly_sdk_key_secret_version.secret_string}
```

Client-side SDKs should use this client-side id:
```
${var.env.name}
```


### Configuring the SDK to use your Dorkly server

Please follow the LaunchDarkly documentation for [configuring SDKs to use a Relay Proxy](https://docs.launchdarkly.com/sdk/features/relay-proxy-configuration/proxy-mode).

Find the SDK-specific section for your SDK; it'll contain a code sample in which one or more endpoint URLs are specified. Copy and use this code sample, setting **all** the URLs to:
```
${var.ld_sdk_endpoint}
```

- <details>
  <summary>Example: Configuring a server-side SDK</summary>

  Check out the LaunchDarkly [hello-go example](https://github.com/launchdarkly/hello-go) and modify the config as follows:

  ```golang
      dorklyConfig := ld.Config{
          ServiceEndpoints: ldcomponents.RelayProxyEndpoints("${var.ld_sdk_endpoint}"),
      }

      ldClient, err := ld.MakeCustomClient("${aws_secretsmanager_secret_version.dorkly_sdk_key_secret_version.secret_string}", dorklyConfig, 10*time.Second)
  ```
  </details>

- <details>
  <summary>Example: Configuring a client-side SDK</summary>

  Check out the LaunchDarkly [hello-js example](https://github.com/launchdarkly/hello-js) and modify the config as follows:

  ```javascript
        // Set clientSideID to your environment name
        const clientSideID = '${var.env.name}';

        // Set up the evaluation context.
        const context = {
          kind: 'user',
          key: 'example-user-key',
        };

        const options = {
          baseUrl: '${var.ld_sdk_endpoint}',
          streamUrl: '${var.ld_sdk_endpoint}',
          eventsUrl: '${var.ld_sdk_endpoint}',
        };

        const ldclient = LDClient.initialize(clientSideID, context, options);
  ```
  </details>

## Other handy bits
All values below and others are available as terraform outputs for easy wiring into your app.

* Endpoint for this environment: `${var.ld_sdk_endpoint}`
* client-side id: `${var.env.name}`

### SDK Key
* SDK Key value: `${aws_secretsmanager_secret_version.dorkly_sdk_key_secret_version.secret_string}`
* AWS secret arn: `${aws_secretsmanager_secret_version.dorkly_sdk_key_secret_version.arn}`
* AWS secret name: `${aws_secretsmanager_secret.dorkly_sdk_key_secret.name}`
* AWS: Get secret via cli: `aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.dorkly_sdk_key_secret.name}  | jq -r .SecretString`

### Mobile Key
* Mobile Key value: `${aws_secretsmanager_secret_version.dorkly_mobile_key_secret_version.secret_string}`
* Aws secret arn: `${aws_secretsmanager_secret_version.dorkly_mobile_key_secret_version.arn}`
* Aws secret name: `${aws_secretsmanager_secret.dorkly_mobile_key_secret.name}`
* Get secret using aws cli: `aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.dorkly_mobile_key_secret.name}  | jq -r .SecretString`

EOF
  commit_message      = "terraform robot: project/environments/${var.env.name}/README.md"
  overwrite_on_create = true
}
