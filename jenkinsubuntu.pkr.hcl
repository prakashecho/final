packer {
  required_plugins {
    amazon = {
      version = ">=1.2.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "Jenkins-AMI"
  instance_type = "t2.small"
  region        = var.region
  source_ami    = "ami-04b70fa74e45c3917"
  ssh_username  = "ubuntu"
  ami_block_device_mappings {
    device_name = "/dev/sda1"
    encrypted   = true
    kms_key_id  = "arn:aws:kms:us-east-1:874599947932:key/22ad3ccd-28a1-4d05-ad73-5f284cea93b3"
    volume_size = 8
    volume_type = "gp2"
  }
}

build {
  name    = "jenkins-build"
  sources = ["source.amazon-ebs.ubuntu"]
  provisioner "shell" {
    inline = [
      "sudo apt update -y"
    ]
  }
}
