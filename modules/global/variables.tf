variable "name" {
  description = "Name to give resources"
}

variable "env" {
  description = "Environment name"
}

variable "tag_prefix_list" {
  description = "List of tag prefixes"
  type        = list(string)
}

// Required for  provisioning assume_role perms for cross account access
variable "target_accounts" {
  description = "List of target accounts"
  type        = list(string)
}