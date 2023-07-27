#!/bin/bash

usage_help="Usage: $0 [-t prod_global/tooling/<version>] [-b <tf_backend_config_prefix>] [-g <global_resource_deploy_from_region>] [-r <tf_state_region>]"
usage() { echo "$usage_help" 1>&2; exit 1; }

# Default values if none provided
tag="prod_global/tooling/1.0"
global_resource_deploy_from_region="us-east-1"
tf_state_region="us-east-1"
while getopts ":t:b:g:r:" o; do
    case "${o}" in
        t)
            tag=${OPTARG}
            ;;
        b)
            tf_backend_config_prefix=${OPTARG}
            ;;
        g)
            global_resource_deploy_from_region=${OPTARG}
            ;;
        r)
            tf_state_region=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$tf_backend_config_prefix" ]; then echo "Please pass in [-b <tf_backend_config_prefix>] Terraform state S3 bucket prefix.  Please see README for details.  Exiting..."; usage; fi
if [ $OPTIND -eq 1 ]; then echo "$usage_help"; echo "No arguments were passed...Trying to run with default values.  If it doesn't succeed, please  read the Prerequisites inside README of this project."; fi
echo "tag is set to $tag"
echo "tf_backend_config_prefix is set to $tf_backend_config_prefix"
echo "global_resource_deploy_from_region is set to $global_resource_deploy_from_region"
echo "tf_state_region is set to $tf_state_region"

ENV=$(echo $tag | cut -d/ -f1 | cut -d_ -f1)
TARGET_DEPLOYMENT_SCOPE=$(echo $tag | cut -d/ -f1 | cut -d_ -f2)
TEAM=$(echo $tag | cut -d/ -f2)
GLOBAL_RESOURCE_DEPLOY_FROM_REGION=$global_resource_deploy_from_region
TARGET_MODULE=$(if [[ ${TARGET_DEPLOYMENT_SCOPE} == *"global"* ]];then echo "module.global"; else echo "module.regional"; fi)
REGION=$(if [[ ${TARGET_DEPLOYMENT_SCOPE} == *"global"* ]];then echo "${GLOBAL_RESOURCE_DEPLOY_FROM_REGION}"; else echo "${TARGET_DEPLOYMENT_SCOPE}"; fi) # default to us-east-1 if global resource deployment
echo "terraform init -reconfigure -backend-config="key=$TEAM/$ENV-$TARGET_DEPLOYMENT_SCOPE/terraform.tfstate" -backend-config="region=$tf_state_region" -backend-config="bucket=$tf_backend_config_prefix-$ENV" -backend-config="dynamodb_table=$tf_backend_config_prefix-lock-$ENV" -backend-config="encrypt=true""
terraform init -reconfigure -backend-config="key=$TEAM/$ENV-$TARGET_DEPLOYMENT_SCOPE/terraform.tfstate" -backend-config="region=$tf_state_region" -backend-config="bucket=$tf_backend_config_prefix-$ENV" -backend-config="dynamodb_table=$tf_backend_config_prefix-lock-$ENV" -backend-config="encrypt=true"
terraform fmt
terraform validate
REGION_TFVARS=$([ -s "environments/${ENV}/${TEAM}/${REGION}.tfvars" ] && echo "-var-file environments/${ENV}/${TEAM}/${REGION}.tfvars" || echo "")
echo "terraform plan -var-file "environments/${ENV}/${TEAM}/variables.tfvars" ${REGION_TFVARS} -var "env=${ENV}" -var "region=${REGION}" -var "tf_backend_config_prefix=${tf_backend_config_prefix}" -var "global_resource_deploy_from_region=${global_resource_deploy_from_region}" -target ${TARGET_MODULE} -out=tfplan"
terraform plan -destroy -var-file "environments/${ENV}/${TEAM}/variables.tfvars" ${REGION_TFVARS} -var "env=${ENV}" -var "region=${REGION}" -var "tf_backend_config_prefix=${tf_backend_config_prefix}" -var "global_resource_deploy_from_region=${global_resource_deploy_from_region}" -target ${TARGET_MODULE} -out=tfplan -compact-warnings