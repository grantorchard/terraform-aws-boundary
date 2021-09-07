module "boundary_api_lb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.5.0"
  # insert the 4 required variables here
  vpc_id  = local.vpc_id
  subnets = local.public_subnets
  security_groups = [
    aws_security_group.lb.id
  ]

  name = "boundary-api"

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.boundary_cert.acm_certificate_arn
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  target_groups = [
    {
      name_prefix      = "cnt"
      backend_protocol = "HTTP"
      backend_port     = 9200
      target_type      = "instance"

      targets = [
        {
          target_id = module.boundary-controller.id
          port      = 9200
        }
      ]
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
  records = [module.boundary_api_lb.lb_dns_name]
}