terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.74"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  region             = data.aws_region.current.name
  account            = data.aws_caller_identity.current.account_id

  tags = {
    Environment = var.env
    Name        = var.name
  }
}

resource "aws_iam_role" "cloudwatch_event_role" {
  name = "cloudwatch-event-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "attach_codebuild_policy" {
  name = "codebuild-policy"
  role        = aws_iam_role.codebuild_role.name
  policy      = data.template_file.codebuild_policy_template.rendered
}

data "template_file" "codebuild_policy_template" {
  template = file("${path.module}/templates/codebuild_iam_policy.tpl")
  vars = {
    account              = local.account
    target_account_roles = jsonencode([for account in var.target_accounts : "arn:aws:iam::${account}:role/InfraBuildRole"])
  }
}

data "aws_iam_policy_document" "codepipeline_assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name        = "codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_policy.json
}

data "template_file" "codepipeline_policy_template" {
  template = file("${path.module}/templates/codepipeline_iam_policy.tpl")
}

resource "aws_iam_role_policy" "attach_codepipeline_policy" {
  name = "codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = data.template_file.codepipeline_policy_template.rendered

}