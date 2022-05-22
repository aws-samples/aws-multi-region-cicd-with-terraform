variable "env" {
  description = "Environment name"
}

variable "tag_prefix_list" {
  description = "List of tag prefixes"
  type        = list(string)
}

variable "build_spec_file" {
  description = "Build spec file name for the pipeline"
  default = {
    "terraform_plan"    = "buildspec-terraform_plan.yml",
    "terraform_apply"   = "buildspec-terraform_apply.yml",
    "terraform_checkov" = "buildspec-terraform_checkov.yml",
    "terraform_tflint" = "buildspec-terraform_tflint.yml"
  }
}

variable "repository_name" {
  description = "Name of the remote source repository"
  type        = string
  default     = "awsome-infra-project"
}

variable "default_branch" {
  description = "Name of the default branch for the repo"
  type        = string
  default     = "main"
}

variable "name" {
  description = "Name to give resources"
}

variable "number_of_azs" {
  description = "Number of azs to deploy to"
}

variable "global_resource_deploy_from_region" {
  description = "Region from which to deploy global resources in our pipeline"
}

variable "source_repo_bucket_prefix" {
  description = "A prefix for S3 bucket name to house the src code in the Source stage post tagging"
}

variable "codebuild_artifacts_prefix" {
  description = "A prefix for S3 bucket name to house the AWS CodeBuild artifacts for cache, etc."
}

variable "codepipeline_artifacts_prefix" {
  description = "A prefix for S3 bucket name to house the AWS CodePipeline artifacts for logs, etc."
}

variable "tf_backend_config_prefix" {
  description = "A name to prefix the s3 bucket for terraform state files and the dyanamodb table for terraform state locks for backend config"
}