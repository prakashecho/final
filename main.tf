provider "aws" {
  region = "us-east-1"
}

variable "target_regions" {
  type    = list(string)
  default = ["us-east-1", "us-east-2", "us-west-1"]
}

data "aws_ami" "source_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["Jenkins-AMI"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_ami_copy" "encrypted_ami_copies" {
  count             = length(var.target_regions)
  name              = "encrypted-ami-${var.target_regions[count.index]}"
  source_ami_id     = data.aws_ami.source_ami.id
  source_ami_region = "us-east-1"
  encrypted         = true
  kms_key_id        = "arn:aws:kms:us-east-1:874599947932:key/22ad3ccd-28a1-4d05-ad73-5f284cea93b3"
  region            = var.target_regions[count.index]
}

resource "aws_ami_launch_permission" "shared_ami" {
  count      = length(var.target_regions)
  account_id = "280435798514"
  image_id   = aws_ami_copy.encrypted_ami_copies[count.index].id
}

resource "aws_kms_key_policy" "key_policy" {
  key_id = "arn:aws:kms:us-east-1:874599947932:key/22ad3ccd-28a1-4d05-ad73-5f284cea93b3"
  policy = jsonencode({
    # ... (Your existing policy)
  })
}
