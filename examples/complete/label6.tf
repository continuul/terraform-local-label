module "label6" {
  source    = "../../"
  name      = "Dolphin"
  stage     = "poc"
  context   = module.label5.context
  delimiter = "."
  prefix    = "eg"

  tags = {
    "Eat"    = "Carrot"
    "Animal" = "Rabbit"
  }
}

output "label6" {
  value = {
    id         = module.label6.id
    name       = module.label6.name
    namespace  = module.label6.namespace
    stage      = module.label6.stage
    attributes = module.label6.attributes
    delimiter  = module.label6.delimiter
  }
}

output "label6_tags" {
  value = module.label6.tags
}

output "label6_context" {
  value = module.label6.context
}
