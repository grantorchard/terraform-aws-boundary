locals {
  public_subnets          = data.terraform_remote_state.this.outputs.public_subnets
  private_subnets         = data.terraform_remote_state.this.outputs.private_subnets
  security_group_outbound = data.terraform_remote_state.this.outputs.security_group_outbound
  security_group_ssh      = data.terraform_remote_state.this.outputs.security_group_ssh
  vpc_id                  = data.terraform_remote_state.this.outputs.vpc_id
  boundary_ami            = [for image in flatten(data.hcp_packer_image_iteration.this.builds[*].images[*]) : image.image_id if image.region == "us-west-2"][0]
  vault_db_path           = "rds_postgres"
}

# Create IAM resources for use by Controller and Worker nodes
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}


resource "aws_iam_instance_profile" "this" {
  name_prefix = "boundary"
  path        = var.instance_profile_path
  role        = aws_iam_role.this.name
}

resource "aws_iam_role" "this" {
  name_prefix        = "controller"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "this" {
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}


# Spin up compute instances from Packer image registry

data "hcp_packer_image_iteration" "this" {
  bucket_name = "boundary"
  channel     = "latest"
}

module "controller_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.6.0"

  name             = "boundary_controller"
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  health_check_type = "EC2"

  vpc_zone_identifier = local.public_subnets


  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
    }
  }

  # Launch template config
  lt_name     = "boundary_controller"
  description = "Launch template for Boundary controller"

  use_lt    = true
  create_lt = true

  # uncomment these lines if you need ssh access for troubleshooting
  # associate_public_ip_address = true
  # key_name             = var.key_name
  target_group_arns = module.boundary_controller_lb.target_group_arns

  image_id         = local.boundary_ami
  instance_type    = var.controller_size
  user_data_base64 = base64gzip(templatefile("${path.module}/templates/controller.hcl.tpl",
      {
        cluster_port      = var.cluster_port
        cluster_lb_fqdn   = "${var.lb_hostname}.${data.aws_route53_zone.this.name}"
        cluster_lb_port   = var.cluster_lb_port
        api_port          = var.api_port
        kms_root          = aws_kms_key.root.id
        kms_worker_auth   = aws_kms_key.worker_auth.id
        kms_recovery      = aws_kms_key.recovery.id
        database_username = var.database_username
        database_password = var.database_password
        database_name     = var.database_name
        database_endpoint = aws_db_instance.this.endpoint
  			tls_disabled      = var.tls_disabled
  			tls_cert_path     = var.tls_cert_path
      }
  ))

  iam_instance_profile_arn = aws_iam_instance_profile.this.arn

  security_groups = [
    local.security_group_outbound,
    local.security_group_ssh,
    aws_security_group.controller.id
  ]
}

module "worker_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.6.0"

  name             = "boundary_worker"
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  health_check_type = "EC2"

  vpc_zone_identifier = local.public_subnets

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
    }
  }

  # Launch template config
  lt_name     = "boundary_worker"
  description = "Launch template for Boundary worker"

  use_lt    = true
  create_lt = true

  # uncomment these lines if you need ssh access for troubleshooting
  # associate_public_ip_address = true
  # key_name             = var.key_name
  target_group_arns = module.boundary_worker_lb.target_group_arns

  image_id         = local.boundary_ami
  instance_type    = var.worker_size
  user_data_base64 = base64gzip(data.template_file.worker_userdata.rendered)
  # base64gzip(templatefile("${path.module}/templates/controller.hcl.tpl",
  #     {
  #       cluster_port      = var.cluster_port
  #       cluster_lb_fqdn   = "${var.lb_hostname}.${data.aws_route53_zone.this.name}"
  #       cluster_lb_port   = var.cluster_lb_port
  #       api_port          = var.api_port
  #       kms_root          = aws_kms_key.root.id
  #       kms_worker_auth   = aws_kms_key.worker_auth.id
  #       kms_recovery      = aws_kms_key.recovery.id
  #       database_username = var.database_username
  #       database_password = var.database_password
  #       database_name     = var.database_name
  #       database_endpoint = aws_db_instance.this.endpoint
  # 			tls_disabled      = var.tls_disabled
  # 			tls_cert_path     = var.tls_cert_path
  #     }
  # ))

  iam_instance_profile_arn = aws_iam_instance_profile.this.arn

  security_groups = [
    local.security_group_outbound,
    local.security_group_ssh,
    aws_security_group.worker.id
  ]
}


# module "boundary-controller" {
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   version = "3.1.0"

#   user_data = base64gzip(data.template_file.controller_userdata.rendered)

#   ami                  = local.boundary_ami
#   instance_type        = var.instance_type
#   key_name             = var.key_name
#   iam_instance_profile = aws_iam_instance_profile.this.name

#   monitoring = true
#   vpc_security_group_ids = [
#     local.security_group_outbound,
#     local.security_group_ssh,
#     aws_security_group.controller.id
#   ]

#   subnet_id = local.public_subnets[0]
# }

