[![Continuul][logo]](https://continuul.solutions)

# terraform-local-label [![Slack Community](https://img.shields.io/badge/slack-@continuul/green.svg?logo=slack)](https://slack.continuul.com)

Terraform module designed to generate consistent names and tags for resources. Use `terraform-local-label` to implement a strict naming convention.

A label follows the following convention: `{namespace}-{environment}-{stage}-{name}-{attributes}`. The delimiter (e.g. `-`) is interchangeable.
The label items are all optional. So if you prefer the term `stage` to `environment` you can exclude environment and the label `id` will look like `{namespace}-{stage}-{name}-{attributes}`.
If attributes are excluded but `stage` and `environment` are included, `id` will look like `{namespace}-{environment}-{stage}-{name}`

It's recommended to use one `terraform-local-label` module for every unique resource of a given resource type.
For example, if you have 10 instances, there should be 10 different labels.
However, if you have multiple different kinds of resources (e.g. instances, security groups, file systems, and elastic ips), then they can all share the same label assuming they are logically related.

All [Continuul modules](https://github.com/continuul?utf8=%E2%9C%93&q=terraform-&type=&language=) use this module to ensure resources can be instantiated multiple times within an account and without conflict.

**NOTE:** The `local` refers to the primary Terraform [provider](https://www.terraform.io/docs/providers/local/index.html) used in this module.

This module only works with Terraform 0.12 or newer.

## Usage

**IMPORTANT:** The `master` branch is used in `source` just as an example. In your code, do not pin to `master` because there may be breaking changes between releases.
Instead pin to the release tag (e.g. `?ref=tags/x.y.z`) of one of our [latest releases](https://github.com/continuul/terraform-local-label/releases).

### Simple Example

```hcl
module "eg_prod_bastion_label" {
  source     = "git::https://github.com/continuul/terraform-local-label.git?ref=master"
  namespace  = "eg"
  stage      = "prod"
  name       = "bastion"
  attributes = ["public"]
  delimiter  = "-"

  tags = {
    "BusinessUnit" = "XYZ",
    "Snapshot"     = "true"
  }
}
```

This will create an `id` with the value of `eg-prod-bastion-public` because when generating `id`, the default order is `namespace`, `environment`, `stage`,  `name`, `attributes`
(you can override it by using the `label_order` variable, see [Advanced Example 3](#advanced-example-3)).

Now reference the label when creating an instance:

```hcl
resource "aws_instance" "eg_prod_bastion_public" {
  instance_type = "t1.micro"
  tags          = module.eg_prod_bastion_label.tags
}
```

Or define a security group:

```hcl
resource "aws_security_group" "eg_prod_bastion_public" {
  vpc_id = var.vpc_id
  name   = module.eg_prod_bastion_label.id
  tags   = module.eg_prod_bastion_label.tags
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```


### Advanced Example

Here is a more complex example with two instances using two different labels. Note how efficiently the tags are defined for both the instance and the security group.

```hcl
module "eg_prod_bastion_abc_label" {
  source     = "git::https://github.com/continuul/terraform-local-label.git?ref=master"
  namespace  = "eg"
  stage      = "prod"
  name       = "bastion"
  attributes = ["abc"]
  delimiter  = "-"

  tags = {
    "BusinessUnit" = "XYZ",
    "Snapshot"     = "true"
  }
}

resource "aws_security_group" "eg_prod_bastion_abc" {
  name = module.eg_prod_bastion_abc_label.id
  tags = module.eg_prod_bastion_abc_label.tags
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "eg_prod_bastion_abc" {
   instance_type          = "t1.micro"
   tags                   = module.eg_prod_bastion_abc_label.tags
   vpc_security_group_ids = [aws_security_group.eg_prod_bastion_abc.id]
}

module "eg_prod_bastion_xyz_label" {
  source     = "git::https://github.com/continuul/terraform-local-label.git?ref=master"
  namespace  = "eg"
  stage      = "prod"
  name       = "bastion"
  attributes = ["xyz"]
  delimiter  = "-"

  tags = {
    "BusinessUnit" = "XYZ",
    "Snapshot"     = "true"
  }
}

resource "aws_security_group" "eg_prod_bastion_xyz" {
  name = module.eg_prod_bastion_xyz_label.id
  tags = module.eg_prod_bastion_xyz_label.tags
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "eg_prod_bastion_xyz" {
   instance_type          = "t1.micro"
   tags                   = module.eg_prod_bastion_xyz_label.tags
   vpc_security_group_ids = [aws_security_group.eg_prod_bastion_xyz.id]
}
```

### Advanced Example 2

Here is a more complex example with an autoscaling group that has a different tagging schema than other resources and requires its tags to be in this format, which this module can generate:

```hcl
tags = [
    {
        key = Name,
        propagate_at_launch = 1,
        value = namespace-stage-name
    },
    {
        key = Namespace,
        propagate_at_launch = 1,
        value = namespace
    },
    {
        key = Stage,
        propagate_at_launch = 1,
        value = stage
    }
]
```

Autoscaling group using propagating tagging below (full example: [autoscalinggroup](examples/autoscalinggroup/main.tf))

```hcl
################################
# terraform-local-label example #
################################
module "label" {
  source    = "../../"
  namespace = "cp"
  stage     = "prod"
  name      = "app"

  tags = {
    BusinessUnit = "Finance"
    ManagedBy    = "Terraform"
  }

  additional_tag_map = {
    propagate_at_launch = "true"
  }
}

#######################
# Launch template     #
#######################
resource "aws_launch_template" "default" {
  # terraform-local-label example used here: Set template name prefix
  name_prefix                           = "${module.label.id}-"
  image_id                              = data.aws_ami.amazon_linux.id
  instance_type                         = "t2.micro"
  instance_initiated_shutdown_behavior  = "terminate"

  vpc_security_group_ids                = [data.aws_security_group.default.id]

  monitoring {
    enabled                             = false
  }
  # terraform-local-label example used here: Set tags on volumes
  tag_specifications {
    resource_type                       = "volume"
    tags                                = module.label.tags
  }
}

######################
# Autoscaling group  #
######################
resource "aws_autoscaling_group" "default" {
  # terraform-local-label example used here: Set ASG name prefix
  name_prefix                           = "${module.label.id}-"
  vpc_zone_identifier                   = data.aws_subnet_ids.all.ids
  max_size                              = "1"
  min_size                              = "1"
  desired_capacity                      = "1"

  launch_template = {
    id                                  = "aws_launch_template.default.id"
    version                             = "$$Latest"
  }

  # terraform-local-label example used here: Set tags on ASG and EC2 Servers
  tags                                  = module.label.tags_as_list_of_maps
}
```

### Advanced Example 3

See [complete example](./examples/complete)

This example shows how you can pass the `context` output of one label module to the next label_module,
allowing you to create one label that has the base set of values, and then creating every extra label
as a derivative of that.

```hcl
module "label1" {
  source      = "git::https://github.com/continuul/terraform-local-label.git?ref=master"
  namespace   = "Hashicorp"
  environment = "UAT"
  stage       = "build"
  name        = "Web Server"
  attributes  = ["fire", "water", "earth", "air"]
  delimiter   = "-"

  label_order = ["name", "environment", "stage", "attributes"]

  tags = {
    "City"        = "Boston"
    "Environment" = "Private"
  }
}

module "label2" {
  source    = "git::https://github.com/continuul/terraform-local-label.git?ref=master"
  context   = module.label1.context
  name      = "Charlie"
  stage     = "test"
  delimiter = "+"

  tags = {
    "City"        = "London"
    "Environment" = "Public"
  }
}

module "label3" {
  source    = "git::https://github.com/continuul/terraform-local-label.git?ref=master"
  name      = "Starfish"
  stage     = "release"
  context   = module.label1.context
  delimiter = "."

  tags = {
    "Eat"    = "Carrot"
    "Animal" = "Rabbit"
  }
}
```

This creates label outputs like this:

```hcl
label1 = {
  "attributes" = [
    "fire",
    "water",
    "earth",
    "air",
  ]
  "delimiter" = "-"
  "id" = "winstonchurchroom-uat-build-fire-water-earth-air"
  "name" = "winstonchurchroom"
  "namespace" = "Hashicorp"
  "stage" = "build"
}
label1_context = {
  "additional_tag_map" = {}
  "attributes" = [
    "fire",
    "water",
    "earth",
    "air",
  ]
  "delimiter" = "-"
  "enabled" = true
  "environment" = "uat"
  "label_order" = [
    "name",
    "environment",
    "stage",
    "attributes",
  ]
  "name" = "winstonchurchroom"
  "namespace" = "Hashicorp"
  "regex_replace_chars" = "/[^a-zA-Z0-9-]/"
  "stage" = "build"
  "tags" = {
    "Attributes" = "fire-water-earth-air"
    "City" = "Boston"
    "Environment" = "Private"
    "Name" = "winstonchurchroom"
    "Namespace" = "Hashicorp"
    "Stage" = "build"
  }
}
label1_tags = {
  "Attributes" = "fire-water-earth-air"
  "City" = "Boston"
  "Environment" = "Private"
  "Name" = "winstonchurchroom"
  "Namespace" = "Hashicorp"
  "Stage" = "build"
}
label2 = {
  "attributes" = [
    "fire",
    "water",
    "earth",
    "air",
  ]
  "delimiter" = "+"
  "id" = "charlie+uat+test+firewaterearthair"
  "name" = "charlie"
  "namespace" = "Hashicorp"
  "stage" = "test"
}
label2_context = {
  "additional_tag_map" = {}
  "attributes" = [
    "fire",
    "water",
    "earth",
    "air",
  ]
  "delimiter" = "+"
  "enabled" = true
  "environment" = "uat"
  "label_order" = [
    "name",
    "environment",
    "stage",
    "attributes",
  ]
  "name" = "charlie"
  "namespace" = "Hashicorp"
  "regex_replace_chars" = "/[^a-zA-Z0-9-]/"
  "stage" = "test"
  "tags" = {
    "Attributes" = "firewaterearthair"
    "City" = "London"
    "Environment" = "Public"
    "Name" = "charlie"
    "Namespace" = "Hashicorp"
    "Stage" = "test"
  }
}
label2_tags = {
  "Attributes" = "firewaterearthair"
  "City" = "London"
  "Environment" = "Public"
  "Name" = "charlie"
  "Namespace" = "Hashicorp"
  "Stage" = "test"
}
label3 = {
  "attributes" = [
    "fire",
    "water",
    "earth",
    "air",
  ]
  "delimiter" = "."
  "id" = "starfish.uat.release.firewaterearthair"
  "name" = "starfish"
  "namespace" = "Hashicorp"
  "stage" = "release"
}
label3_context = {
  "additional_tag_map" = {}
  "attributes" = [
    "fire",
    "water",
    "earth",
    "air",
  ]
  "delimiter" = "."
  "enabled" = true
  "environment" = "uat"
  "label_order" = [
    "name",
    "environment",
    "stage",
    "attributes",
  ]
  "name" = "starfish"
  "namespace" = "Hashicorp"
  "regex_replace_chars" = "/[^a-zA-Z0-9-]/"
  "stage" = "release"
  "tags" = {
    "Animal" = "Rabbit"
    "Attributes" = "firewaterearthair"
    "City" = "Boston"
    "Eat" = "Carrot"
    "Environment" = "uat"
    "Name" = "starfish"
    "Namespace" = "Hashicorp"
    "Stage" = "release"
  }
}
label3_tags = {
  "Animal" = "Rabbit"
  "Attributes" = "firewaterearthair"
  "City" = "Boston"
  "Eat" = "Carrot"
  "Environment" = "uat"
  "Name" = "starfish"
  "Namespace" = "Hashicorp"
  "Stage" = "release"
}
```

## Doc generation

Code formatting and documentation for variables and outputs is generated using [pre-commit-terraform hooks](https://github.com/antonbabenko/pre-commit-terraform) which uses [terraform-docs](https://github.com/segmentio/terraform-docs).

Follow [these instructions](https://github.com/antonbabenko/pre-commit-terraform#how-to-install) to install pre-commit locally.

And install `terraform-docs` with `go get github.com/segmentio/terraform-docs` or `brew install terraform-docs`.

## Contributing

Report issues/questions/feature requests on in the [issues](https://github.com/continuul/terraform-local-label/issues/new) section.

Full contributing [guidelines are covered here](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/.github/CONTRIBUTING.md).

## Change log

- The [changelog](https://github.com/continuul/terraform-local-label/tree/master/CHANGELOG.md) captures all important release notes.

## Authors

- Created by [Robert Buck](https://github.com/rbuck).
- Many thanks to [Cloud Posse](https://github.com/terraform-aws-modules/terraform-aws-eks/graphs/contributors) from whom this module is derived.

## License

MIT Licensed. See [LICENSE](https://github.com/continuul/terraform-local-label/tree/master/LICENSE) for full details.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12.0 |

## Providers

No provider.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_tag\_map | Additional tags for appending to each tag map | `map(string)` | `{}` | no |
| attributes | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| casing | Casing, that is to be used for tag keys, e.g. `lower`, `title`, `upper` | `string` | `"title"` | no |
| context | Default context to use for passing state between label invocations | <pre>object({<br>    name                      = string<br>    environment               = string<br>    owner                     = string<br>    group                     = string<br>    namespace                 = string<br>    stage                     = string<br>    enabled                   = bool<br>    casing                    = string<br>    delimiter                 = string<br>    prefix                    = string<br>    attributes                = list(string)<br>    label_order               = list(string)<br>    tags                      = map(string)<br>    additional_tag_map        = map(string)<br>    regex_replace_chars       = string<br>    regex_replace_chars_owner = string<br>    replacement               = string<br>  })</pre> | <pre>{<br>  "additional_tag_map": {},<br>  "attributes": [],<br>  "casing": "title",<br>  "delimiter": "",<br>  "enabled": true,<br>  "environment": "",<br>  "group": "",<br>  "label_order": [],<br>  "name": "",<br>  "namespace": "",<br>  "owner": "",<br>  "prefix": "",<br>  "regex_replace_chars": "",<br>  "regex_replace_chars_owner": "",<br>  "replacement": "",<br>  "stage": "",<br>  "tags": {}<br>}</pre> | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes` | `string` | `"-"` | no |
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | `string` | `""` | no |
| group | Group, who is associated with a resource, typically for cost allocation and tracking, e.g. 'finance' or 'ap' | `string` | `""` | no |
| label\_order | The naming order of the id output and Name tag | `list(string)` | `[]` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | `string` | `""` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `""` | no |
| owner | Owner, who is responsible for the resource, e.g. 'john.smith' or 'doctor' | `string` | `""` | no |
| prefix | Prefix to be used with tags | `string` | `""` | no |
| regex\_replace\_chars | Regex to replace chars with empty string (or `replacement`) in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed | `string` | `"/[^a-zA-Z0-9-]/"` | no |
| regex\_replace\_chars\_owner | Regex to replace owner chars with empty string (or `replacement`) in `namespace`, `environment`, `stage` and `name`. By default only hyphens, underscrores, dots, plus, letters and digits are allowed, all other chars are removed. This is to permit owner to be an email name or slack id | `string` | `"/[^a-zA-Z0-9-+_.@]/"` | no |
| replacement | Replacement character for regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed | `string` | `""` | no |
| stage | Stage, e.g. 'source', 'build', 'test', 'deploy', 'release' | `string` | `""` | no |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| attributes | List of attributes |
| context | Context of this module to pass to other label modules |
| delimiter | Delimiter between `namespace`, `environment`, `stage`, `name` and `attributes` |
| environment | Normalized environment |
| group | Normalized group |
| id | Disambiguated ID |
| label\_order | The naming order of the id output and Name tag |
| name | Normalized name |
| namespace | Normalized namespace |
| owner | Normalized owner |
| stage | Normalized stage |
| tags | Normalized Tag map |
| tags\_as\_list\_of\_maps | Additional tags as a list of maps, which can be used in several AWS resources |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Related Projects

None.

## Help

**Got a question?** We got answers.

File a GitHub [issue](https://github.com/continuul/terraform-local-label/issues), or join our [Slack Community][slack].

## Slack Community

Join our [Open Source Community][slack] on Slack. It's **FREE** for everyone! Our "Continuul" community is where you get to talk with others who share a similar vision for how to rollout and manage infrastructure. This is the best place to talk shop, ask questions, solicit feedback, and work together as a community to build totally *continuul* infrastructure.

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/continuul/terraform-local-label/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing this project or [help out](https://cpco.io/help-out) with our other projects, we would love to hear from you!

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull Request** so that we can review your changes

**NOTE:** Be sure to merge the latest changes from "upstream" before making a pull request!

## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## About

[Continuul, LLC][website] maintains and funds this project.

  [logo]: https://avatars3.githubusercontent.com/u/57697117?s=60&v=4
  [docs]: https://cpco.io/docs?utm_source=github&utm_medium=readme&utm_campaign=continuul/terraform-local-label&utm_content=docs
  [website]: https://cpco.io/homepage?utm_source=github&utm_medium=readme&utm_campaign=continuul/terraform-local-label&utm_content=website
  [github]: https://cpco.io/github?utm_source=github&utm_medium=readme&utm_campaign=continuul/terraform-local-label&utm_content=github
  [slack]: https://cpco.io/slack?utm_source=github&utm_medium=readme&utm_campaign=continuul/terraform-local-label&utm_content=slack
