data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "all" {}

locals {
  region             = data.aws_region.current.name
  account            = data.aws_caller_identity.current.account_id
  availability_zones = slice(sort(data.aws_availability_zones.all.zone_ids), 0, var.number_of_azs)
  tags = {
    Environment = var.env
    Name        = var.name
  }
}

module "vpc" {
  source = "./vpc"

  vpc_name               = var.name
  vpc_azs                = local.availability_zones
  vpc_single_nat_gateway = true
  vpc_enable_nat_gateway   = true
  vpc_enable_dns_hostnames = true
  vpc_tags                 = local.tags
}

module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.7.0"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.vpc_security_group_ids]

  endpoints = {
    codebuild = {
      # interface endpoint
      service             = "codebuild"
      tags                = { Name = "codebuild-vpc-endpoint" }
      private_dns_enabled = true
      subnet_ids          = module.vpc.vpc_private_subnet_ids
    },
    codecommit = {
      # interface endpoint
      service             = "codecommit"
      tags                = { Name = "codecommit-vpc-endpoint" }
      private_dns_enabled = true
      subnet_ids          = module.vpc.vpc_private_subnet_ids
    },
    codepipeline = {
      # interface endpoint
      service             = "codepipeline"
      tags                = { Name = "codepipeline-vpc-endpoint" }
      private_dns_enabled = true
      subnet_ids          = module.vpc.vpc_private_subnet_ids
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = module.vpc.vpc_private_subnet_ids
      security_group_ids  = [module.vpc.vpc_security_group_tls_id]
    }
  }

  tags = local.tags
}

data aws_iam_role codebuild_role {
  name = "codebuild-role"
}

data "template_file" "key_policy_template" {
  template = file("${path.module}/templates/key_policy.tpl")
  vars = {
    region         = local.region
    account        = local.account
    codebuild-role =  data.aws_iam_role.codebuild_role.arn
  }
}

data "template_file" "s3_bucket_policy_codebuild_template" {
  template = file("${path.module}/templates/s3_bucket_policy_codebuild.tpl")
  vars = {
    cb_s3_resource_arns = jsonencode(concat([ aws_s3_bucket.codebuild_artifacts.arn, format("%s/*", aws_s3_bucket.codebuild_artifacts.arn) ],
                                            [ format("arn:aws:s3:::%s*", var.tf_backend_config_prefix) ],
                                            flatten([for tag in var.tag_prefix_list : [aws_s3_bucket.codepipeline_artifacts[tag].arn,
                                                                                       aws_s3_bucket.codebuild_repo_artifacts[tag].arn,
                                                                                       format("%s/*", aws_s3_bucket.codepipeline_artifacts[tag].arn),
                                                                                       format("%s/*", aws_s3_bucket.codebuild_repo_artifacts[tag].arn)]])))
  }
}

resource "aws_iam_role_policy" "attach_s3_bucket_policy" {
  name_prefix = "s3_bucket-policy-cb"
  role = data.aws_iam_role.codebuild_role.id
  policy = data.template_file.s3_bucket_policy_codebuild_template.rendered
}

data "template_file" "s3_bucket_policy_codepipeline_template" {
  template = file("${path.module}/templates/s3_bucket_policy_codepipeline.tpl")
  vars = {
    cp_s3_resource_arns = jsonencode(concat([ aws_s3_bucket.codebuild_artifacts.arn, format("%s/*", aws_s3_bucket.codebuild_artifacts.arn) ],
                                            flatten([for tag in var.tag_prefix_list : [aws_s3_bucket.codepipeline_artifacts[tag].arn,
                                                                                       aws_s3_bucket.codebuild_repo_artifacts[tag].arn,
                                                                                       format("%s/*", aws_s3_bucket.codepipeline_artifacts[tag].arn),
                                                                                       format("%s/*", aws_s3_bucket.codebuild_repo_artifacts[tag].arn)]
                                                    ]
                                            )
                                      )
                          )
  }
}

data aws_iam_role codepipeline_role {
  name = "codepipeline-role"
}

resource "aws_iam_role_policy" "attach_s3_bucket_policy_codepipeline" {
  name_prefix = "s3_bucket-policy-cp"
  role = data.aws_iam_role.codepipeline_role.id
  policy = data.template_file.s3_bucket_policy_codepipeline_template.rendered
}

resource "aws_kms_key" "artifact_encryption_key" {
  description             = "Code artifact kms key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.template_file.key_policy_template.rendered
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  for_each = toset(var.tag_prefix_list)
  bucket = aws_s3_bucket.codebuild_repo_artifacts[each.key].id
  eventbridge = true
}

resource "aws_s3_bucket" "codebuild_repo_artifacts" {
  for_each = toset(var.tag_prefix_list)
  bucket_prefix   = "${var.source_repo_bucket_prefix}-artifacts-${each.key}"
  acl      = "private"
  force_destroy = true // for demo purposes only

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.artifact_encryption_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codebuild_repo_artifacts" {
  for_each = toset(var.tag_prefix_list)
  bucket = aws_s3_bucket.codebuild_repo_artifacts[each.key].id

  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls=true
}

resource "aws_s3_bucket" "codebuild_artifacts" {
  bucket_prefix = var.codebuild_artifacts_prefix
  force_destroy = true // for demo purposes only

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.artifact_encryption_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codebuild_artifacts" {
  bucket = aws_s3_bucket.codebuild_artifacts.id

  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls=true
}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  for_each = toset(var.tag_prefix_list)
  bucket_prefix   = "${var.codepipeline_artifacts_prefix}-${each.key}"
  force_destroy = true // for demo purposes only

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.artifact_encryption_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  for_each = toset(var.tag_prefix_list)
  bucket = aws_s3_bucket.codepipeline_artifacts[each.key].id

  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls=true
}

resource "aws_codebuild_project" "terraform" {
  for_each      = toset(keys(var.build_spec_file))
  name          = each.key
  description   = "${each.key}_codebuild_project"
  build_timeout = "15"
  service_role  = data.aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.artifact_encryption_key.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild_artifacts.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild_artifacts.bucket}/build-log"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.cwd}/modules/regional/${var.build_spec_file[each.key]}")
  }

  source_version = var.default_branch

  vpc_config {
    vpc_id             = module.vpc.vpc_id
    subnets            = module.vpc.vpc_private_subnet_ids
    security_group_ids = [module.vpc.vpc_security_group_ids]
  }

  tags = {
    Environment = var.env
  }
}

resource "aws_codepipeline" "infra_pipeline" {
  for_each = toset(var.tag_prefix_list)
  name     = "${each.key}-${var.repository_name}-deploy"
  role_arn = data.aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts[each.key].bucket
    type     = "S3"

        encryption_key {
          id   = aws_kms_key.artifact_encryption_key.arn
          type = "KMS"
        }
  }

  stage {
    name = "Source"

    action {
      name      = "${each.key}-${var.repository_name}-Source"
      category  = "Source"
      owner     = "AWS"
      provider  = "S3"
      version   = "1"
      namespace = "S3_SOURCE"
      output_artifacts = [
      "source"]
      region = local.region

      configuration = {
        S3Bucket             = aws_s3_bucket.codebuild_repo_artifacts[each.key].bucket
        S3ObjectKey          = aws_codebuild_project.build_upon_tag_creation[each.key].name
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Terraform_tflint"

    action {
      name     = "${var.repository_name}-Terraform_Tflint"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"
      input_artifacts = [
        "source"]
      output_artifacts = [
        "tflint"]
      namespace = "TFLINT"
      run_order = 1

      configuration = {
        ProjectName = aws_codebuild_project.terraform["terraform_tflint"].name
        EnvironmentVariables = jsonencode([
          {
            name  = "GLOBAL_RESOURCE_DEPLOY_FROM_REGION",
            value = var.global_resource_deploy_from_region,
            type  = "PLAINTEXT"
          },
          {
            name  = "TF_BACKEND_CONFIG_PREFIX",
            value = var.tf_backend_config_prefix,
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Terraform_checkov"

    action {
      name     = "${var.repository_name}-Terraform_Checkov"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"
      input_artifacts = [
      "source"]
      output_artifacts = [
      "checkov"]
      namespace = "CHECKOV"
      run_order = 1

      configuration = {
        ProjectName = aws_codebuild_project.terraform["terraform_checkov"].name
        EnvironmentVariables = jsonencode([
          {
            name  = "ACCOUNT",
            value = local.account,
            type  = "PLAINTEXT"
          }
        ])
      }
    }

    action {
      name      = "${var.repository_name}-Terraform_Checkov_Approval"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 2

      configuration = {
        CustomData         = "checkov: #{CHECKOV.failures}, #{CHECKOV.tests}"
        ExternalEntityLink = "#{CHECKOV.review_link}"
      }
    }
  }


  stage {
    name = "Terraform_Build"

    action {
      name     = "${var.repository_name}-Terraform_Plan"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      input_artifacts = [
      "source"]
      output_artifacts = [
      "plan"]
      namespace = "TF"
      version   = "1"
      run_order = 1

      configuration = {
        ProjectName = aws_codebuild_project.terraform["terraform_plan"].name
        EnvironmentVariables = jsonencode([
          {
            name  = "ENV",
            value = "#{TFLINT.ENV}",
            type  = "PLAINTEXT"
          },
          {
            name  = "TEAM",
            value = "#{TFLINT.TEAM}",
            type  = "PLAINTEXT"
          },
          {
            name  = "TARGET_DEPLOYMENT_SCOPE",
            value = "#{TFLINT.TARGET_DEPLOYMENT_SCOPE}",
            type  = "PLAINTEXT"
          },
          {
            name  = "REGION_TFVARS",
            value = "#{TFLINT.REGION_TFVARS}",
            type  = "PLAINTEXT"
          },
          {
            name  = "TARGET_MODULE",
            value = "#{TFLINT.TARGET_MODULE}",
            type  = "PLAINTEXT"
          },
          {
            name  = "REGION",
            value = "#{TFLINT.REGION}",
            type  = "PLAINTEXT"
          },
          {
            name  = "TF_BACKEND_CONFIG_PREFIX",
            value = var.tf_backend_config_prefix,
            type  = "PLAINTEXT"
          }
        ])
      }
    }

    action {
      name      = "${var.repository_name}-Terraform_Apply_Approval"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 2

      configuration = {
        CustomData         = "Please review and approve the terraform plan"
        ExternalEntityLink = "https://#{TF.pipeline_region}.console.aws.amazon.com/codesuite/codebuild/${local.account}/projects/#{TF.build_id}/build/#{TF.build_id}%3A#{TF.build_tag}/?region=#{TF.pipeline_region}"
      }
    }

    action {
      name     = "${var.repository_name}-Terraform_Apply"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      input_artifacts = [
      "plan"]
      output_artifacts = [
      "apply"]
      version   = "1"
      run_order = 3

      configuration = {
        ProjectName = aws_codebuild_project.terraform["terraform_apply"].name
        EnvironmentVariables = jsonencode([
          {
            name  = "ENV",
            value = "#{TFLINT.ENV}",
            type  = "PLAINTEXT"
          },
          {
            name  = "TEAM",
            value = "#{TFLINT.TEAM}",
            type  = "PLAINTEXT"
          },
          {
            name  = "TARGET_DEPLOYMENT_SCOPE",
            value = "#{TFLINT.TARGET_DEPLOYMENT_SCOPE}",
            type  = "PLAINTEXT"
          },
          {
            name  = "REGION_TFVARS",
            value = "#{TFLINT.REGION_TFVARS}",
            type  = "PLAINTEXT"
          },
          {
            name  = "TARGET_MODULE",
            value = "#{TFLINT.TARGET_MODULE}",
            type  = "PLAINTEXT"
          },
          {
            name  = "REGION",
            value = "#{TFLINT.REGION}",
            type  = "PLAINTEXT"
          },
          {
            name  = "TF_BACKEND_CONFIG_PREFIX",
            value = var.tf_backend_config_prefix,
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }
}

resource "aws_codebuild_project" "build_upon_tag_creation" {
  for_each      = toset(var.tag_prefix_list)
  name          = "${each.key}-${aws_codecommit_repository.awsomerepo.repository_name}-src"
  description   = "src_codebuild_project"
  build_timeout = "5"
  service_role  = data.aws_iam_role.codebuild_role.arn
  encryption_key = aws_kms_key.artifact_encryption_key.arn

  artifacts {
    type     = "S3"
    location = aws_s3_bucket.codebuild_repo_artifacts[each.key].bucket
    name      = "${each.key}-${aws_codecommit_repository.awsomerepo.repository_name}-src"
    packaging = "ZIP"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild_repo_artifacts[each.key].bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.codebuild_repo_artifacts[each.key].bucket}/build-log"
    }
  }

  source {
    type      = "CODECOMMIT"
    location  = aws_codecommit_repository.awsomerepo.clone_url_http
    buildspec = file("${path.cwd}/modules/regional/buildspec-tagged_source.yml")
  }

  source_version = var.default_branch

  vpc_config {
    vpc_id  = module.vpc.vpc_id
    subnets = module.vpc.vpc_private_subnet_ids
    security_group_ids = [
      module.vpc.vpc_security_group_ids]
  }

  tags = {
    Environment = var.env
  }
}