<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_endpoints"></a> [endpoints](#module\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 3.7.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.trigger_build_on_tag_updates](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.trigger_pipeline_on_s3_updates](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_codebuild_project.build_upon_tag_creation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_project.terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codecommit_repository.awsomerepo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_repository) | resource |
| [aws_codepipeline.infra_pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_iam_role_policy.attach_cwe_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.attach_s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.attach_s3_bucket_policy_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_key.artifact_encryption_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.codebuild_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.codebuild_repo_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.codepipeline_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_notification.bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_public_access_block.codebuild_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.codebuild_repo_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.codepipeline_artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_availability_zones.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_role.cloudwatch_event_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_role.codepipeline_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [template_file.cloudwatchevent_policy_template](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.key_policy_template](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.s3_bucket_policy_codebuild_template](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.s3_bucket_policy_codepipeline_template](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_build_spec_file"></a> [build\_spec\_file](#input\_build\_spec\_file) | Build spec file name for the pipeline | `map` | <pre>{<br>  "terraform_apply": "buildspec-terraform_apply.yml",<br>  "terraform_checkov": "buildspec-terraform_checkov.yml",<br>  "terraform_plan": "buildspec-terraform_plan.yml",<br>  "terraform_tflint": "buildspec-terraform_tflint.yml"<br>}</pre> | no |
| <a name="input_codebuild_artifacts_prefix"></a> [codebuild\_artifacts\_prefix](#input\_codebuild\_artifacts\_prefix) | A prefix for S3 bucket name to house the AWS CodeBuild artifacts for cache, etc. | `any` | n/a | yes |
| <a name="input_codepipeline_artifacts_prefix"></a> [codepipeline\_artifacts\_prefix](#input\_codepipeline\_artifacts\_prefix) | A prefix for S3 bucket name to house the AWS CodePipeline artifacts for logs, etc. | `any` | n/a | yes |
| <a name="input_default_branch"></a> [default\_branch](#input\_default\_branch) | Name of the default branch for the repo | `string` | `"main"` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `any` | n/a | yes |
| <a name="input_global_resource_deploy_from_region"></a> [global\_resource\_deploy\_from\_region](#input\_global\_resource\_deploy\_from\_region) | Region from which to deploy global resources in our pipeline | `any` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name to give resources | `any` | n/a | yes |
| <a name="input_number_of_azs"></a> [number\_of\_azs](#input\_number\_of\_azs) | Number of azs to deploy to | `any` | n/a | yes |
| <a name="input_repository_name"></a> [repository\_name](#input\_repository\_name) | Name of the remote source repository | `string` | `"awsome-infra-project"` | no |
| <a name="input_source_repo_bucket_prefix"></a> [source\_repo\_bucket\_prefix](#input\_source\_repo\_bucket\_prefix) | A prefix for S3 bucket name to house the src code in the Source stage post tagging | `any` | n/a | yes |
| <a name="input_tag_prefix_list"></a> [tag\_prefix\_list](#input\_tag\_prefix\_list) | List of tag prefixes | `list(string)` | n/a | yes |
| <a name="input_tf_backend_config_prefix"></a> [tf\_backend\_config\_prefix](#input\_tf\_backend\_config\_prefix) | A name to prefix the s3 bucket for terraform state files and the dyanamodb table for terraform state locks for backend config | `any` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->