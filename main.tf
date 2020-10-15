data terraform_remote_state "this" {
  backend = "remote"

  config = {
    organization = "grantorchard"
    workspaces = {
      name = "terraform-aws-core"
    }
  }
}

locals {
  public_subnets = data.terraform_remote_state.this.outputs.public_subnets
  private_subnets = data.terraform_remote_state.this.outputs.private_subnets
  security_group_outbound = data.terraform_remote_state.this.outputs.security_group_outbound
  security_group_ssh = data.terraform_remote_state.this.outputs.security_group_ssh
  vpc_id = data.terraform_remote_state.this.outputs.vpc_id
}

data aws_route53_zone "this" {
  name         = "go.hashidemos.io"
  private_zone = false
}

data aws_ami "ubuntu" {
  most_recent = true

  filter {
    name = "tag:application"
    values = ["boundary-0.1"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["711129375688"] # Canonical
}

module "boundary" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.15.0"

  name = "boundary"

  #user_data_base64 = base64gzip(data.template_file.userdata.rendered)

  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = var.key_name
  iam_instance_profile = aws_iam_instance_profile.this.name

  monitoring = true
  vpc_security_group_ids = [
    local.security_group_outbound,
    local.security_group_ssh,
    module.security_group_boundary.this_security_group_id
  ]

  subnet_id = local.public_subnets[0]
  tags = var.tags
}

resource aws_route53_record "this" {
  zone_id = data.aws_route53_zone.this.id
  name    = "${var.hostname}.${data.aws_route53_zone.this.name}"
  type    = "A"
  ttl     = "300"
  records = module.boundary.public_ip
}



module "security_group_boundary" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "boundary-boundary"
  description = "boundary boundary access"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 9200
      to_port     = 9202
      protocol    = "tcp"
      description = "Boundary boundary ingress"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = var.tags
}

data aws_iam_policy_document "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document "this" {
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}


resource aws_iam_instance_profile "this" {
  name_prefix = var.hostname
  path        = var.instance_profile_path
  role        = aws_iam_role.this.name
}

resource aws_iam_role "this" {
  name_prefix        = var.hostname
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource aws_iam_role_policy "this" {
  name   = var.hostname
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}


resource aws_kms_key "root" {
  description             = "Boundary root key"
  deletion_window_in_days = 10
  tags = var.tags
}

resource aws_kms_key "worker-auth" {
  description             = "Boundary worker-auth key"
  deletion_window_in_days = 10
  tags = var.tags
}

resource aws_kms_key "recovery" {
  description             = "Boundary recovery key"
  deletion_window_in_days = 10
  tags = var.tags
}

/*

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "2.18.0"

  engine = "postgres"
  engine_version = "12.4"

  instance_class = "db.m3.medium"
  subnet_ids = local.private_subnets
  vpc_security_group_ids = [module.security_group_postgres.this_security_group_id]

  name = "boundary"
  username = "boundary"
  password = "Hashi123!"
  identifier = "boundary"
  port = 5432

  create_db_parameter_group = false
  create_db_option_group = false

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  allocated_storage = 5

  # insert the 11 required variables here
}
*/