variable "owner" {
  type        = string
  default     = ""
  description = "Owner, who is responsible for the resource, e.g. 'john.smith' or 'doctor'"
}

variable "group" {
  type        = string
  default     = ""
  description = "Group, who is associated with a resource, typically for cost allocation and tracking, e.g. 'finance' or 'ap'"
}

variable "namespace" {
  type        = string
  default     = ""
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp'"
}

variable "name" {
  type        = string
  default     = ""
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT'"
}

variable "stage" {
  type        = string
  default     = ""
  description = "Stage, e.g. 'source', 'build', 'test', 'deploy', 'release'"
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

variable "casing" {
  type        = string
  default     = "title"
  description = "Casing, that is to be used for tag keys, e.g. `lower`, `title`, `upper`"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes`"
}

variable "prefix" {
  type        = string
  default     = ""
  description = "Prefix to be used with tags"
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit','XYZ')`"
}

variable "additional_tag_map" {
  type        = map(string)
  default     = {}
  description = "Additional tags for appending to each tag map"
}

variable "context" {
  type = object({
    name                = string
    environment         = string
    owner               = string
    group               = string
    namespace           = string
    stage               = string
    enabled             = bool
    casing              = string
    delimiter           = string
    prefix              = string
    attributes          = list(string)
    label_order         = list(string)
    tags                = map(string)
    additional_tag_map  = map(string)
    regex_replace_chars = string
    replacement         = string
  })
  default = {
    name                = ""
    environment         = ""
    owner               = ""
    group               = ""
    namespace           = ""
    stage               = ""
    enabled             = true
    casing              = "title"
    delimiter           = ""
    prefix              = ""
    attributes          = []
    label_order         = []
    tags                = {}
    additional_tag_map  = {}
    regex_replace_chars = ""
    replacement         = ""
  }
  description = "Default context to use for passing state between label invocations"
}

variable "label_order" {
  type        = list(string)
  default     = []
  description = "The naming order of the id output and Name tag"
}

variable "regex_replace_chars" {
  type        = string
  default     = "/[^a-zA-Z0-9-]/"
  description = "Regex to replace chars with empty string (or `replacement`) in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed"
}

variable "replacement" {
  type        = string
  default     = ""
  description = "Replacement character for regex to replace chars with empty string in `namespace`, `environment`, `stage` and `name`. By default only hyphens, letters and digits are allowed, all other chars are removed"
}
