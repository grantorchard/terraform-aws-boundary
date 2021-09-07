module "boundary_cert" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.2"

  domain_name = "${var.lb_hostname}.${data.aws_route53_zone.this.name}"
  zone_id     = data.aws_route53_zone.this.id
}

