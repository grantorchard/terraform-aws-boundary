locals {}

source "amazon-ebs" "boundary" {

  region = var.region

  source_ami_filter {
    filters = {
       virtualization-type = "hvm"
       name = "ubuntu/images/*ubuntu-bionic-18.04-amd64-server-*"
       root-device-type = "ebs"
    }
    owners = ["099720109477"]
    most_recent = true
  }

  instance_type = "t2.medium"
  ssh_username = "ubuntu"
  ami_name = "boundary-{{timestamp}}"

  tags = {
    owner = var.owner
    application = "boundary-${var.boundary_version}"
    Base_AMI_Name = "{{ .SourceAMIName }}"
  }
}
