#!/bin/bash

function configure_aws_cli_for_tooling_account()
{
  echo "Configuring aws cli using aws configure for tooling account"
  read -r -p "Enter aws_access_key_id for the tooling account IAM user with necessary permissions to create IAM resources: " aws_access_key_id
  read -r -p "Enter aws_secret_access_key for this user: " aws_secret_access_key
  read -r -p "Enter default.region: " default_region
  aws configure --profile aws_sample_central_tooling set aws_access_key_id $aws_access_key_id
  aws configure --profile aws_sample_central_tooling set aws_secret_access_key $aws_secret_access_key
  aws configure --profile aws_sample_central_tooling set default.region $default_region
  export AWS_PROFILE=aws_sample_central_tooling
  echo "Current user is"
  aws sts get-caller-identity --profile aws_sample_central_tooling
}

# Create InfraBuildRole in the central tooling account and ensure this role can be assumed by your IAM user
# Ensure this role has the necessary permissions to create the CI/CD resources in this account as well as to the Terraform remote state management S3 buckets and DynamoDB tables.
function create_tooling_infra_build_role()
{
  user_arn=$(aws sts get-caller-identity --profile aws_sample_central_tooling --query 'Arn' --output text)
  cat << EOF > trust_policy.json
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
              "AWS": "$user_arn"
          },
          "Action": "sts:AssumeRole"
        }
      ]
}
EOF

  infra_build_role="InfraBuildRole"
  echo "Checking if $infra_build_role role exists in the tooling account"
  role_exists=$(aws iam get-role --profile aws_sample_central_tooling --role-name $infra_build_role)
  if [ "$role_exists" ]; then
    printf "%s exists.  Returning...\n" $infra_build_role
    return
  fi
  echo "Creating InfraBuildRole for deployment of CI/CD resources into tooling account"
  aws iam create-role --profile aws_sample_central_tooling --role-name $infra_build_role --assume-role-policy-document file://trust_policy.json
  read -r -p "Enter the IAM policy ARN created in the tooling account to attach to InfraBuildRole. Ensure it has the necessary permissions to create the CI/CD resources and Terraform remote state management resources in the central tooling account: " infra_build_iam_policy
  get_iam_policy="aws iam get-policy --profile aws_sample_central_tooling --policy-arn $infra_build_iam_policy"
  eval $get_iam_policy
  ret_code=$?
  if [ $ret_code != 0 ]; then
    printf "Error: [%d] when retrieving the IAM policy using: '$get_iam_policy'" $ret_code
    printf "Please verify the IAM policy to attach to InfraBuildRole exists and if not create it. Exiting..."
    exit $ret_code
  fi
  aws iam attach-role-policy --profile aws_sample_central_tooling --policy-arn $infra_build_iam_policy --role-name $infra_build_role
}

# Create a CloudOps IAM role in the central tooling account.
# This role is what's used by the DevOps engineers to interact with the CodeCommit repo among other things.
function create_tooling_cloudops_role()
{
  user_arn=$(aws sts get-caller-identity --profile aws_sample_central_tooling --query 'Arn' --output text)
  cat << EOF > trust_policy.json
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
              "AWS": "$user_arn"
          },
          "Action": "sts:AssumeRole"
        }
      ]
}
EOF

  # Check if role already exists
  cloud_ops_role="CloudOps"
  echo "Checking if $cloud_ops_role role exists in the tooling account"
  role_exists=$(aws iam get-role --profile aws_sample_central_tooling --role-name $cloud_ops_role)
  if [ "$role_exists" ]; then
    printf "%s exists.  Returning...\n" $cloud_ops_role
    return
  fi

  echo "Creating $cloud_ops_role role for the devops team member in the tooling account"
  aws iam create-role --profile aws_sample_central_tooling --role-name $cloud_ops_role --assume-role-policy-document file://trust_policy.json
  aws iam attach-role-policy --profile aws_sample_central_tooling --policy-arn arn:aws:iam::aws:policy/AWSCodeCommitPowerUser --role-name $cloud_ops_role
  aws iam attach-role-policy --profile aws_sample_central_tooling --policy-arn arn:aws:iam::aws:policy/AWSConfigUserAccess --role-name $cloud_ops_role
  aws iam attach-role-policy --profile aws_sample_central_tooling --policy-arn arn:aws:iam::aws:policy/AWSCloudTrail_ReadOnlyAccess --role-name $cloud_ops_role
  aws iam attach-role-policy --profile aws_sample_central_tooling --policy-arn arn:aws:iam::aws:policy/AWSCodeBuildReadOnlyAccess --role-name $cloud_ops_role
  aws iam attach-role-policy --profile aws_sample_central_tooling --policy-arn arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess --role-name $cloud_ops_role
  # As needed for the use case, you can use AWSCodePipelineApproverAccess instead that's more restricted
  # aws iam attach-role-policy --profile aws_sample_central_tooling --policy-arn arn:aws:iam::aws:policy/AWSCodePipelineApproverAccess --role-name $cloud_ops_role
  aws iam attach-role-policy --profile aws_sample_central_tooling --policy-arn arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess --role-name $cloud_ops_role
  aws iam attach-role-policy --profile aws_sample_central_tooling --policy-arn arn:aws:iam::aws:policy/AmazonEventBridgeReadOnlyAccess --role-name $cloud_ops_role
}

configure_aws_cli_for_tooling_account
create_tooling_cloudops_role
create_tooling_infra_build_role