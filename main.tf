provider "aws" {
  region = "us-east-1"
}

# Retrieve the existing encrypted AMI ID
data "aws_ami" "source_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Jenkins-AMI"]  # Adjust the filter based on the actual name of the AMI
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Define the list of target regions for AMI copy
variable "target_regions" {
  type    = list(string)
  default = ["us-east-1", "us-east-2", "us-west-1"]  # Add the target regions you want to copy the AMI to
}

# Copy the existing encrypted AMI to multiple regions
resource "aws_ami_copy" "encrypted_ami_copies" {
  count = length(var.target_regions)

  name              = "encrypted-ami-${var.target_regions[count.index]}"
  source_ami_id     = data.aws_ami.source_ami.id
  source_ami_region = "us-east-1"
  encrypted         = true
  kms_key_id        = "arn:aws:kms:us-east-1:874599947932:key/22ad3ccd-28a1-4d05-ad73-5f284cea93b3"
  region            = var.target_regions[count.index]
}

# Share the copied AMIs with other AWS accounts in respective regions
resource "aws_launch_permission" "shared_ami" {
  count = length(var.target_regions)

  account_id = "280435798514"  # Add the AWS account ID you want to share with
  image_id   = aws_ami_copy.encrypted_ami_copies[count.index].id
}

# Optionally, you can modify the snapshot permissions as well for each region
resource "null_resource" "share_snapshot" {
  count = length(var.target_regions)

  provisioner "local-exec" {
    command = "aws ec2 modify-snapshot-attribute --region ${var.target_regions[count.index]} --snapshot-id ${aws_ami_copy.encrypted_ami_copies[count.index].snapshot_id} --attribute createVolumePermission --operation-type add --user-ids <280435798514>"
  }
}

# Share the KMS key with other accounts
resource "aws_kms_key_policy" "key_policy" {
  key_id = "arn:aws:kms:us-east-1:874599947932:key/22ad3ccd-28a1-4d05-ad73-5f284cea93b3"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "key-default-1",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::874599947932:role/KMSAdminRole"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow usage for encrypted resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::874599947932:root",  # Your AWS account
            "280435798514",                  # Add the AWS account IDs you want to share with
            
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      }
    ]
  })
}
