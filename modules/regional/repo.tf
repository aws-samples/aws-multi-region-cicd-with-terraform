resource "aws_codecommit_repository" "awsomerepo" {
  repository_name = var.repository_name
  description     = "This is the Sample IaC Repository for Infrastructure Resources"
  default_branch  = var.default_branch
}

data "template_file" "cloudwatchevent_policy_template" {
  template = file("${path.module}/templates/cloud_watch_event_policy.tpl")
  vars = {
    pipeline_arn = jsonencode([for tag in var.tag_prefix_list : aws_codepipeline.infra_pipeline[tag].arn])
    codebuildproj_arn = jsonencode([for tag in var.tag_prefix_list : aws_codebuild_project.build_upon_tag_creation[tag].arn])
  }
}

data aws_iam_role cloudwatch_event_role {
  name = "cloudwatch-event-role"
}

resource "aws_iam_role_policy" "attach_cwe_policy" {
  name_prefix = "cwe-policy"
  role        = data.aws_iam_role.cloudwatch_event_role.name

  policy = data.template_file.cloudwatchevent_policy_template.rendered
}

// CodeBuild as Target for git tag push
resource "aws_cloudwatch_event_rule" "trigger_build_on_tag_updates" {
  for_each    = toset(var.tag_prefix_list)
  name        = "trigger_codebuild_on_tag_update_${each.key}"
  description = "Trigger code build on ${each.key} tag update"

  event_pattern = <<EOF
{
  "source": [
    "aws.codecommit"
  ],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "resources": [
    "${aws_codecommit_repository.awsomerepo.arn}"
  ],
  "detail": {
    "event": [
      "referenceCreated",
      "referenceUpdated"
    ],
    "repositoryName": [
      "${aws_codecommit_repository.awsomerepo.repository_name}"
    ],
    "referenceType": [
      "tag"
    ],
    "referenceName": [
      { "prefix": "${each.key}" }
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "codebuild" {
  for_each  = toset(var.tag_prefix_list)
  rule      = aws_cloudwatch_event_rule.trigger_build_on_tag_updates[each.key].name
  target_id = "SendToCodeBuild"
  arn       = aws_codebuild_project.build_upon_tag_creation[each.key].arn
  role_arn  = data.aws_iam_role.cloudwatch_event_role.arn

  input_transformer {
    input_paths = {
      git_tag = "$.detail.referenceName"
    }
    input_template = "{ \"environmentVariablesOverride\": [ { \"name\": \"TAG\", \"value\": <git_tag> } ]}"
  }
}

resource "aws_cloudwatch_event_rule" "trigger_pipeline_on_s3_updates" {
  for_each    = toset(var.tag_prefix_list)
  name        = "trigger_pipeline_on_s3_updates_${each.key}"
  description = "Trigger code pipeline on s3 update"

  event_pattern = <<EOF
{
    "source": [ "aws.s3" ],
    "detail-type": [ "Object Created" ],
      "detail": {
        "bucket": {
            "name": [ "${aws_s3_bucket.codebuild_repo_artifacts[each.key].bucket}" ]
        },
        "object": {
            "key": [ "${aws_codebuild_project.build_upon_tag_creation[each.key].name}" ]
        }
    }
}
EOF
}

resource "aws_cloudwatch_event_target" "codepipeline" {
  for_each  = toset(var.tag_prefix_list)
  rule      = aws_cloudwatch_event_rule.trigger_pipeline_on_s3_updates[each.key].name
  target_id = "SendToCodePipeline-${each.key}"
  arn       = aws_codepipeline.infra_pipeline[each.key].arn
  role_arn  = data.aws_iam_role.cloudwatch_event_role.arn
}