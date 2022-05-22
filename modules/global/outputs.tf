output "codebuild_role_arn" {
  value = aws_iam_role.codebuild_role.arn
}

output "codepipeline_role_arn" {
  value = aws_iam_role.codepipeline_role.arn
}

output "cloudwatch_event_role_arn" {
  value = aws_iam_role.cloudwatch_event_role.arn
}