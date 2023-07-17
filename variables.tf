variable "region" {
  type        = string
  description = "Target region"
  default     = "us-east-1"
}

variable "global_resource_deploy_from_region" {
  type        = string
  description = "Region from which to deploy global resources in our pipeline"
  default     = "us-east-1"
}

variable "account" {
  type        = string
  description = "Target AWS account number"
}

variable "env" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "tag_prefix_list" {
  type        = list(string)
  description = "List of tag prefixes"
  default     = ["dev", "qa", "staging", "prod"]
}

# Required for  provisioning assume_role perms for cross account access
variable "target_accounts" {
  type        = list(string)
  description = "List of target accounts"
}

variable "number_of_azs" {
  type        = number
  description = "Number of azs to deploy to"
  default     = 3
}

variable "tf_backend_config_prefix" {
  type        = string
  description = "A name to prefix the S3 bucket for terraform state files and the DynamoDB table for terraform state locks for backend config"
}

variable "source_repo_bucket_prefix" {
  type        = string
  description = "A prefix for S3 bucket name to house the src code in the Source stage post tagging"
  default     = "awsome-cb-repo"
}

variable "codebuild_artifacts_prefix" {
  type        = string
  description = "A prefix for S3 bucket name to house the AWS CodeBuild artifacts for cache, etc."
  default     = "awsome-cb-artifact"
}

variable "codepipeline_artifacts_prefix" {
  type        = string
  description = "A prefix for S3 bucket name to house the AWS CodePipeline artifacts for cache, etc."
  default     = "awsome-cp-artifact"
}