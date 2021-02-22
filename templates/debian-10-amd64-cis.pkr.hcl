variable "source_fingerprint" {
  type = string
}

variable "artifact_dir" {
  type = string
}

variable "ami_name" {
  type    = string
  default = "debian-10-amd64-cis"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami_owner" {
  type    = string
  default = "136693071363"
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
      name                = "debian-10-amd64-20210208-542"
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
    hardening          = "cis"
    os_version         = "debian"
    nase_ami_name      = "{{ .SourceAMIName }}"
    extra              = "{{ .SourceAMITags.TagName }}"
    source_fingerprint = var.source_fingerprint
  }

  metadata_options {
    http_endpoint = "disabled"
  }
}

build {

  sources = ["source.amazon-ebs.ebs"]

  provisioner "shell" {
    execute_command = "{{.Vars}} sudo -E -H bash '{{.Path}}'"
    inline = [
      "apt-get update -y",
      "apt-get install -y python3-pip git",
      "python3 --version",
      "python3 -m pip install --upgrade pip",
      "python3 -m pip install ansible==3.0.0",
      "ansible-playbook --version",
    ]
  }

  provisioner "ansible-local" {
    command         = "PYTHONUNBUFFERED=1 sudo -E ansible-playbook"
    playbook_dir    = "playbooks"
    playbook_files  = ["playbooks/debian-server.yml"]
    extra_arguments = ["-vv", "-e", "'ansible_python_interpreter=/usr/bin/python3'"]
  }

  provisioner "file" {
    sources = [
      "/tmp/debian-cis-apply.log",
      "/tmp/debian-cis-audit-all.log",
    ]
    destination = "${var.artifact_dir}/"
    direction   = "download"
  }

}

