variable "source_fingerprint" {
  type = string
}

variable "ami_name" {
  type    = string
  default = "kibana-7-11-1-amd64"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami_owner" {
  type    = string
  default = "390820182370"
}

variable "kibana_version" {
  type    = string
  default = "7.11.1"
}

locals {
  source_short_fingerprint = substr(sha256(var.source_fingerprint), 0, 16)
}

source "amazon-ebs" "ebs" {
  ami_name      = "${var.ami_name}-${local.source_short_fingerprint}"
  instance_type = "t3.micro"
  region        = var.region

  # https://wiki.debian.org/Cloud/AmazonEC2Image/Buster
  source_ami_filter {
    filters = {
      name                = "debian-10-amd64-cis-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [var.source_ami_owner]
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    volume_size           = 30
    volume_type           = "gp2"
    delete_on_termination = true
  }

  ssh_interface = "public_ip"
  ssh_username  = "admin"
  ssh_port      = 22
  communicator  = "ssh"

  tags = {
    application         = "kibana"
    application_version = var.kibana_version
    nase_ami_name       = "{{ .SourceAMIName }}"
    extra               = "{{ .SourceAMITags.TagName }}"
    source_fingerprint  = var.source_fingerprint
  }

  metadata_options {
    http_endpoint = "disabled"
  }
}

build {

  sources = ["source.amazon-ebs.ebs"]

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    inline = [
      "wget --progress=dot:mega https://artifacts.elastic.co/downloads/kibana/kibana-${var.kibana_version}-linux-x86_64.tar.gz",
      "tar -xzf kibana-${var.kibana_version}-linux-x86_64.tar.gz",
      "mv kibana-${var.kibana_version} kibana",
      # kibana/bin/kibana to execute kibana
    ]
  }

}
