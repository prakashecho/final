packer {
  required_plugins {
    amazon = {
      version = ">=1.2.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  access_key     = ""
  secret_key     = ""
  ami_name       = "Jenkins4"
  instance_type  = "t2.micro"
  region         = "us-east-1"
  source_ami     = "ami-04b70fa74e45c3917"
  ssh_username   = "ubuntu"
  encrypt_boot   = true
  kms_key_id     = "22ad3ccd-28a1-4d05-ad73-5f284cea93b3"
}

build {
  name = "jenkins"
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt update -y"
    ]
  }
}
