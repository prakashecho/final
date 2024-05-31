provider "aws" {
  region = "us-east-1"
}

variable "source_ami_id" {
  description = "The AMI ID from the Packer build"
  type        = string
}

resource "aws_kms_key_policy" "existing_key_policy" {
  key_id = "arn:aws:kms:us-east-1:874599947932:key/22ad3ccd-28a1-4d05-ad73-5f284cea93b3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::874599947932:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::280435798514:root"
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
      "Sid": "Allow attachment of persistent resources",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::280435798514:root"
      },
      "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ami_launch_permission" "share_ami" {
  image_id   = var.source_ami_id
  account_id = "280435798514"
}
