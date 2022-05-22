#!/bin/bash

function configure_aws_cli_for_workload_account()
{
    echo "Configuring aws cli using aws configure for the workload account"
    read -r -p "Enter aws_access_key_id for the workload account IAM user with necessary permissions to create IAM resources: " aws_access_key_id
    read -r -p "Enter aws_secret_access_key for this user: " aws_secret_access_key
    read -r -p "Enter default.region: " default_region
    aws configure --profile aws_sample_workload_account set aws_access_key_id $aws_access_key_id
    aws configure --profile aws_sample_workload_account set aws_secret_access_key $aws_secret_access_key
    aws configure --profile aws_sample_workload_account set default.region $default_region
    export AWS_PROFILE=aws_sample_workload_account
    echo "Current User is"
    aws sts get-caller-identity --profile aws_sample_workload_account
}

# Creates the workload account IAM role named InfraBuildRole in the target workload account.
# See details on cross account IAM roles at https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html
# including this step https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html#tutorial_cross-account-with-roles-2
function create_workload_account_role()
{
  # Get the central tooling account number in which codebuild-role IAM role exists
  # The CodeBuild build inside the pipeline runs as this IAM role "arn:aws:iam::$tooling_account_number:role/codebuild-role"
  # We need to ensure the InfraBuildRole in the workload account can be assumed by this role.
  read -r -p "Enter the CI/CD central tooling account number:" tooling_account_number
  if ! [[ $tooling_account_number =~ ^[0-9]{12}$ ]]; then
    printf "%s is not an account number.  Please provide a valid account number.  Exiting...\n" $tooling_account_number
    exit 1
  fi
  # Deployments into target workload account: "codebuild-role" needs to be able to assume target workload's "InfraBuildRole" for deployments
  # Destroying resources in target workload account for this sample: "InfraBuildRole" in the tooling account needs to be able to assume target workload's "InfraBuildRole"
  # for destroying the resources in the target workload account. This "destroy" functionality could be made available via a pipeline instead as well but that is outside the scope of this sample.
  cat << EOF > workload_trust_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": { "AWS": "arn:aws:iam::$tooling_account_number:role/codebuild-role" },
        "Action": "sts:AssumeRole"
      },
      {
              "Effect": "Allow",
              "Principal": { "AWS": "arn:aws:iam::$tooling_account_number:role/InfraBuildRole" },
              "Action": "sts:AssumeRole"
      }
  ]
}
EOF

  infra_build_role="InfraBuildRole"
  echo "Checking if $infra_build_role role exists in the workload account"
  role_exists=$(aws iam get-role --profile aws_sample_workload_account --role-name $infra_build_role)
  if [ "$role_exists" ]; then
    printf "%s exists.  Returning...\n" $infra_build_role
    return
  fi
    aws iam create-role --profile aws_sample_workload_account --role-name $infra_build_role --assume-role-policy-document file://workload_trust_policy.json
    read -r -p "Enter the IAM policy ARN created in the workload account to attach to $infra_build_role. Ensure it has the necessary permissions to create the workload infra resources in this account: " infra_build_iam_policy
    get_iam_policy="aws iam get-policy --profile aws_sample_workload_account --policy-arn $infra_build_iam_policy"
    eval $get_iam_policy
    ret_code=$?
    if [ $ret_code != 0 ]; then
      printf "Error: [%d] when retrieving the IAM policy using: '$get_iam_policy'" $ret_code
      printf "Please verify the IAM policy exists and if not, create it. Exiting..."
      exit $ret_code
    fi
    aws iam attach-role-policy --profile aws_sample_workload_account --policy-arn $infra_build_iam_policy --role-name $infra_build_role
}

configure_aws_cli_for_workload_account
create_workload_account_role