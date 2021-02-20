variable "ami_name" {
  type    = string
  default = "debian-10-amd64-ami"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "ebs" {
  ami_name      = "packer ${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.region

  # https://wiki.debian.org/Cloud/AmazonEC2Image/Buster
  source_ami_filter {
    filters = {
      name                = "debian-10-amd64-20210208-542"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["136693071363"]
  }

  ssh_interface = "private_ip"
  ssh_username  = "admin"
  ssh_port      = 22
  communicator  = "ssh"

  tags = {
    os_version    = "Debian"
    Release       = "Latest"
    Base_AMI_Name = "{{ .SourceAMIName }}"
    Extra         = "{{ .SourceAMITags.TagName }}"
  }

  metadata_options {
    http_endpoint = "disabled"
  }
}

build {
  sources = ["source.amazon-ebs.ebs"]
}

