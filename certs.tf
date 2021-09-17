module "boundary_cert" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.2"

  domain_name = "${var.lb_hostname}.${data.aws_route53_zone.this.name}"
  zone_id     = data.aws_route53_zone.this.id
}

# module "boundary_controller_cert" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 3.2"

#   domain_name = "${var.controller_lb_hostname}.${data.aws_route53_zone.this.name}"
#   zone_id     = data.aws_route53_zone.this.id
# }

# module "boundary_worker_cert" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 3.2"

#   domain_name = "${var.worker_lb_hostname}.${data.aws_route53_zone.this.name}"
#   zone_id     = data.aws_route53_zone.this.id
# }