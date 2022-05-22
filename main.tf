data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name = "demo"
}

# Regional CI/CD Resources such as CodeBuild, CodePipeline, CodeCommit resources
module "regional" {
  source                             = "./modules/regional"
  env                                = var.env
  tag_prefix_list                    = var.tag_prefix_list
  name                               = local.name
  number_of_azs                      = var.number_of_azs
  global_resource_deploy_from_region = var.global_resource_deploy_from_region
  codebuild_artifacts_prefix         = var.codebuild_artifacts_prefix
  source_repo_bucket_prefix          = var.source_repo_bucket_prefix
  codepipeline_artifacts_prefix      = var.codepipeline_artifacts_prefix
  tf_backend_config_prefix           = var.tf_backend_config_prefix
}

# Provider to deploy global resources from the region set in var.global_resource_deploy_from_region
provider "aws" {
  alias  = "global_resource_deploy_from_region"
  region = var.global_resource_deploy_from_region
  assume_role {
    role_arn     = "arn:aws:iam::${var.account}:role/InfraBuildRole"
    session_name = "INFRA_BUILD"
  }
}

# Global CI/CD resources such as IAM roles
module "global" {
  source          = "./modules/global"
  env             = var.env
  target_accounts = var.target_accounts
  tag_prefix_list = var.tag_prefix_list
  name            = local.name

  providers = {
    aws = aws.global_resource_deploy_from_region
  }
}