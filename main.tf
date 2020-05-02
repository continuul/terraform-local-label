locals {

  defaults = {
    label_order = [
      "namespace",
      "environment",
      "stage",
      "name",
    "attributes"]
    casing      = "title"
    delimiter   = "-"
    prefix      = ""
    replacement = ""
    # The `sentinel` should match the `regex_replace_chars`, so it will be replaced with the `replacement` value
    sentinel = "~"
    attributes = [
    ""]
  }

  # The values provided by variables supersede the values inherited from the context

  enabled             = var.enabled
  regex_replace_chars = coalesce(var.regex_replace_chars, var.context.regex_replace_chars)
  replacement         = coalesce(var.replacement, var.context.replacement, local.defaults.replacement, local.defaults.sentinel) == local.defaults.sentinel ? local.defaults.replacement : coalesce(var.replacement, var.context.replacement, local.defaults.replacement, local.defaults.sentinel)
  prefix_is_empty     = coalesce(var.prefix, var.context.prefix, local.defaults.sentinel) == local.defaults.sentinel
  prefix              = local.prefix_is_empty ? local.defaults.prefix : lower(coalesce(var.prefix, var.context.prefix))

  name_is_empty        = coalesce(var.name, var.context.name, local.defaults.sentinel) == local.defaults.sentinel
  name                 = local.name_is_empty ? "" : lower(replace(coalesce(var.name, var.context.name, local.defaults.sentinel), local.regex_replace_chars, local.replacement))
  stage_is_empty       = coalesce(var.stage, var.context.stage, local.defaults.sentinel) == local.defaults.sentinel
  stage                = local.stage_is_empty ? "" : lower(replace(coalesce(var.stage, var.context.stage, local.defaults.sentinel), local.regex_replace_chars, local.replacement))
  environment_is_empty = coalesce(var.environment, var.context.environment, local.defaults.sentinel) == local.defaults.sentinel
  environment          = local.environment_is_empty ? "" : lower(replace(coalesce(var.environment, var.context.environment, local.defaults.sentinel), local.regex_replace_chars, local.replacement))

  owner_is_empty     = coalesce(var.owner, var.context.owner, local.defaults.sentinel) == local.defaults.sentinel
  owner              = local.owner_is_empty ? "" : lower(replace(coalesce(var.owner, var.context.owner, local.defaults.sentinel), local.regex_replace_chars, local.replacement))
  group_is_empty     = coalesce(var.group, var.context.group, local.defaults.sentinel) == local.defaults.sentinel
  group              = local.group_is_empty ? "" : lower(replace(coalesce(var.group, var.context.group, local.defaults.sentinel), local.regex_replace_chars, local.replacement))
  namespace_is_empty = coalesce(var.namespace, var.context.namespace, local.defaults.sentinel) == local.defaults.sentinel
  namespace          = local.namespace_is_empty ? "" : lower(replace(coalesce(var.namespace, var.context.namespace, local.defaults.sentinel), local.regex_replace_chars, local.replacement))

  casing             = coalesce(lower(var.casing), lower(var.context.casing), local.defaults.casing)
  delimiter          = coalesce(var.delimiter, var.context.delimiter, local.defaults.delimiter)
  label_order        = length(var.label_order) > 0 ? var.label_order : (length(var.context.label_order) > 0 ? var.context.label_order : local.defaults.label_order)
  additional_tag_map = merge(var.context.additional_tag_map, var.additional_tag_map)

  # Names should conform to the Cloud Conformity pattern
  # (i.e. ^ec2-(ue1|uw1|uw2|ew1|ec1|an1|an2|as1|as2|se1)-([1-2]{1})([a-c]{1})-(d|t|s|p)-([a-z0-9\\-]+)$)

  # Supplied tags are not subject to prefix rules, they are preserved as is so
  # that the module supports special cases like 'Name' on AWS, and so that any
  # vendor tag prefixed tags are preserved.
  # n.b. The application of the `title` function to the key by the upstream
  # project here has been removed; we believe that if the user specificaly
  # overrides `tags` with a local merge, e.g. in the case to support a local
  # definition of 'Name', we should never title or lower case the tag. User
  # expressed intent should be respected.
  normalized_tags = { for l in keys(var.tags) : l => lower(var.tags[l]) if length(var.tags[l]) > 0 }

  # Merge attributes
  attributes = compact(distinct(concat(var.attributes, var.context.attributes, local.defaults.attributes)))

  # Context tags are not subject to prefix rules, it is assumed that prior
  # label chains may have had their own prefixes, thus we should not double
  # apply prefixes. Only the current local tags and subsequent chain contexts
  # are subject to prefix rules.
  tags = merge(var.context.tags, local.generated_tags, local.normalized_tags)

  tags_as_list_of_maps = flatten([
    for key in keys(local.tags) : merge(
      {
        key   = key
        value = local.tags[key]
    }, var.additional_tag_map)
  ])

  # standard tags are subject to prefix rules
  tags_context = {
    # For AWS we need `Name` to be disambiguated since it has a special meaning
    name        = local.id
    stage       = local.stage
    environment = local.environment

    owner     = local.owner
    group     = local.group
    namespace = local.namespace

    attributes = local.id_context.attributes
  }

  # standard tags are subject to prefix rules
  generated_tags = {
    for l in keys(local.tags_context) :
    local.casing == "lower" ? (length(local.prefix) > 0 ? join(":", [local.prefix, lower(l)]) : lower(l))
    : local.casing == "title" ? (length(local.prefix) > 0 ? join(":", [local.prefix, title(l)]) : title(l))
    : (length(local.prefix) > 0 ? join(":", [local.prefix, upper(l)]) : upper(l))
    => local.tags_context[l] if length(local.tags_context[l]) > 0
  }

  id_context = {
    name        = local.name
    stage       = local.stage
    environment = local.environment

    owner     = local.owner
    group     = local.group
    namespace = local.namespace

    attributes = lower(replace(join(local.delimiter, local.attributes), local.regex_replace_chars, local.replacement))
  }

  labels = [for l in local.label_order : local.id_context[l] if length(local.id_context[l]) > 0]

  id = lower(join(local.delimiter, local.labels))

  # Context of this label to pass to other label modules
  output_context = {
    enabled = local.enabled

    name        = local.name
    stage       = local.stage
    environment = local.environment

    owner     = local.owner
    group     = local.group
    namespace = local.namespace

    attributes          = local.attributes
    tags                = local.tags
    casing              = local.casing
    delimiter           = local.delimiter
    prefix              = local.prefix
    label_order         = local.label_order
    regex_replace_chars = local.regex_replace_chars
    replacement         = local.replacement
    additional_tag_map  = local.additional_tag_map
  }

}
