provider "aws" {
  region = "us-east-1"
}

variable "packer_ami_name" {
  description = "The AMI name from the Packer build"
  type        = string
}

data "aws_ami" "packer_ami" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = [var.packer_ami_name]
  }
}

resource "aws_ami_copy" "encrypted_ami1" {
  name              = "encrypted-ami1"
  source_ami_id     = data.aws_ami.packer_ami.id
  source_ami_region = "us-east-1"
  encrypted         = true
  kms_key_id        = "arn:aws:kms:us-east-1:874599947932:key/22ad3ccd-28a1-4d05-ad73-5f284cea93b3"
}

output "new_ami_id" {
  value = aws_ami_copy.encrypted_ami1.id
}

resource "aws_kms_key_policy" "existing_key_policy" {
  key_id = aws_ami_copy.encrypted_ami1.kms_key_id
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
  image_id   = aws_ami_copy.encrypted_ami1.id
  account_id = "280435798514"
}

data "aws_ebs_snapshot" "snapshot" {
  most_recent = true
  filter {
    name   = "description"
    values = ["*${aws_ami_copy.encrypted_ami1.id}*"]
  }
}

resource "null_resource" "share_snapshot" {
  provisioner "local-exec" {
    command = "aws ec2 modify-snapshot-attribute --snapshot-id ${data.aws_ebs_snapshot.snapshot.id} --attribute createVolumePermission --operation-type add --user-ids 280435798514"
  }
}
