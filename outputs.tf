output "account_id" {
  description = "The effective account id in which Terraform is operating"
  value       = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  description = "The effective user arn that Terraform is running as"
  value       = data.aws_caller_identity.current.arn
}

output "caller_user" {
  description = "The effective user id that Terraform is running as"
  value       = data.aws_caller_identity.current.user_id
}

output "region" {
  description = "The region in which Terraform is operating"
  value       = data.aws_region.current.id
}