module "label7" {
  source    = "../../"
  name      = "Dolphin"
  stage     = "poc"
  delimiter = "."

  tags = module.label6.tags
}

output "label7" {
  value = {
    id         = module.label7.id
    name       = module.label7.name
    namespace  = module.label7.namespace
    stage      = module.label7.stage
    attributes = module.label7.attributes
    delimiter  = module.label7.delimiter
  }
}

output "label7_tags" {
  value = module.label7.tags
}

output "label7_context" {
  value = module.label7.context
}
