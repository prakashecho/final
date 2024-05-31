provider "aws" {
  region = "us-east-1"
}

# Output from Packer workflow
variable "packer_ami_id" {}

# Copy the source AMI and encrypt it using the existing KMS key
resource "aws_ami_copy" "encrypted_ami1" {
  name              = "encrypted-ami1"
  source_ami_id     = var.packer_ami_id
  source_ami_region = "us-east-1"
  encrypted         = true
  kms_key_id        = "arn:aws:kms:us-east-1:874599947932:key/22ad3ccd-28a1-4d05-ad73-5f284cea93b3"
}

output "new_ami_id" {
  value = aws_ami_copy.encrypted_ami1.id
}

# Update the policy of the existing KMS key to allow usage by another AWS account
# This part remains the same as your original code

# Share the AMI with the specified account
resource "aws_ami_launch_permission" "share_ami" {
  image_id   = aws_ami_copy.encrypted_ami1.id
  account_id = "280435798514"
}

# Fetch the most recent EBS snapshot related to the newly created encrypted AMI
# This part remains the same as your original code

# Share the snapshot with the specified account
# This part remains the same as your original code
