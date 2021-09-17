module "boundary_controller_lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.5.0"

  vpc_id  = local.vpc_id
  subnets = local.public_subnets
  security_groups = [
    aws_security_group.lb.id
  ]

  name = "boundary-controller"

  https_listeners = [
    {
      port            = var.api_lb_port
      protocol        = "HTTPS"
      certificate_arn = module.boundary_cert.acm_certificate_arn
			target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = var.api_lb_port
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
		{
      port            = var.cluster_lb_port
      protocol        = "HTTP"
      #certificate_arn = module.boundary_controller_cert.acm_certificate_arn
			target_group_index = 1
    }
  ]

  target_groups = [
    {
      name_prefix      = "api"
      backend_protocol = "HTTP"
      backend_port     = var.api_port
      target_type      = "instance"
    },
    {
      name_prefix      = "cnt"
      backend_protocol = "HTTP"
      backend_port     = var.cluster_port
      target_type      = "instance"
    }
  ]
}

module "boundary_worker_lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.5.0"

  load_balancer_type = "network"

  vpc_id  = local.vpc_id
  subnets = local.public_subnets

  name = "boundary-worker"

  https_listeners = [
    {
      port            = var.worker_lb_port
      protocol        = "TLS"
      certificate_arn = module.boundary_worker_cert.acm_certificate_arn
    }
  ]

  target_groups = [
    {
      name_prefix      = "wrk"
      backend_protocol = "TCP"
      backend_port     = var.worker_port
      target_type      = "instance"
    }
  ]
}

data "aws_route53_zone" "this" {
  name         = var.domain
  private_zone = false
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.id
  name    = "${var.lb_hostname}.${data.aws_route53_zone.this.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [module.boundary_controller_lb.lb_dns_name]
}

resource "aws_route53_record" "controller" {
  zone_id = data.aws_route53_zone.this.id
  name    = "${var.controller_lb_hostname}.${data.aws_route53_zone.this.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [module.boundary_controller_lb.lb_dns_name]
}

resource "aws_route53_record" "worker" {
  zone_id = data.aws_route53_zone.this.id
  name    = "${var.worker_lb_hostname}.${data.aws_route53_zone.this.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [module.boundary_worker_lb.lb_dns_name]
}