module "label8" {
  source      = "../../"
  namespace   = "Hashicorp"
  environment = "UAT"
  stage       = "build"
  name        = "Web Server"
  attributes  = ["fire", "water", "earth", "air"]
  delimiter   = "-"
  prefix      = "cs"
  owner       = "john.smith+cicd@mail.com"
  replacement = ""

  label_order = ["name", "environment", "stage", "attributes"]

  tags = {
    "City"        = "Boston"
    "Environment" = "Private"
  }
}

output "label8" {
  value = {
    id         = module.label8.id
    name       = module.label8.name
    namespace  = module.label8.namespace
    stage      = module.label8.stage
    attributes = module.label8.attributes
    delimiter  = module.label8.delimiter
  }
}

output "label8_tags" {
  value = module.label8.tags
}

output "label8_context" {
  value = module.label8.context
}
