{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow access through Amazon S3 for all principals in the account that are authorized to use Amazon S3",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "s3.${region}.amazonaws.com",
          "kms:CallerAccount": "${account}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${codebuild-role}"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Principal": {
            "Service": "logs.${region}.amazonaws.com"
        },
        "Action": [
            "kms:Encrypt*",
            "kms:Decrypt*",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:Describe*"
        ],
        "Resource": "*",
        "Condition": {
            "ArnEquals": {
                "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${region}:${account}:log-group:log-group"
            }
        }
    },
    {
      "Sid": "Enable IAM policies",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${account}:root"
       },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
