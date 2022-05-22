{
  "Version": "2012-10-17",
  "Statement": [
    {
         "Effect": "Allow",
         "Action": [
             "codebuild:CreateReportGroup",
             "codebuild:CreateReport",
             "codebuild:UpdateReport",
             "codebuild:BatchPutTestCases",
             "codebuild:BatchPutCodeCoverages"
         ],
         "Resource": [
            "arn:aws:codebuild:*:${account}:report-group/*"
         ]
    },
    {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": ${target_account_roles}
    },
    {
      "Sid": "AllowBuildOutputStreamingToDefaultLogGroup",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:logs:*:*:log-group:*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
        "Sid": "AllowDDBTerraformStateLockAccess",
        "Effect": "Allow",
        "Action": [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:DeleteItem"
        ],
        "Resource": "*"
   },
   {
      "Sid": "AllowPullSourceCodeFromCodeCommit",
      "Action": "codecommit:GitPull",
      "Resource": "*",
      "Effect": "Allow"
   },
   {
      "Sid": "AllowAccessCodeBuildSSMParameters",
      "Effect": "Allow",
      "Action": "ssm:GetParameters",
      "Resource": "arn:aws:ssm:*:*:parameter/CodeBuild/*"
   },
   {
      "Sid": "AllowRunningBuildInVpc",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
   },
   {
      "Sid": "AllowBuildServiceToCreateENI",
      "Effect": "Allow",
      "Action": "ec2:CreateNetworkInterfacePermission",
      "Resource": "arn:aws:ec2:*:*:network-interface/*",
      "Condition": {
        "StringEquals": {
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
   }
 ]
}