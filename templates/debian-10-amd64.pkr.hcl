variable "source_fingerprint" {
  type = string
}

variable "artifact_dir" {
  type = string
}

variable "ami_name" {
  type    = string
  default = "debian-10-amd64-ami"
}

variable "region" {
  type    = string
  default = "us-east-1"
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
    owners      = ["136693071363"]
  }

  ssh_interface = "public_ip"
  ssh_username  = "admin"
  ssh_port      = 22
  communicator  = "ssh"

  tags = {
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
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y python3-pip",
      "python3 -m pip install --upgrade pip",
      "python3 -m pip install --upgrade ansible",
    ]
  }

  provisioner "ansible-local" {
    command         = "PYTHONUNBUFFERED=1 ansible-playbook"
    playbook_dir    = "./playbooks"
    playbook_files  = ["./playbooks/debian-server.yml"]
    extra_arguments = ["-vv"]
  }

  provisioner "file" {
    source      = "/tmp/debian-cis.log"
    destination = "${var.artifact_dir}/debian-cis.log"
    direction   = "download"
  }

}

