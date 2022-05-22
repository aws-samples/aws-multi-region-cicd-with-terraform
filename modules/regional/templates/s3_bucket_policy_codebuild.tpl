{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Sid": "AllowS3Access",
          "Action": [
            "s3:List*",
            "s3:CreateBucket",
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation"
          ],
          "Resource": ${cb_s3_resource_arns},
          "Effect": "Allow"
        }
    ]
}