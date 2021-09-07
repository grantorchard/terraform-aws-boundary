resource "aws_security_group" "controller" {
  vpc_id = local.vpc_id
  name   = "boundary_controller"
}

resource "aws_security_group" "worker" {
  vpc_id = local.vpc_id
  name   = "boundary_worker"
}

resource "aws_security_group" "rds" {
  vpc_id = local.vpc_id
  name   = "boundary_database"
}

resource "aws_security_group" "lb" {
  vpc_id = local.vpc_id
  name   = "boundary_api_lb"
}

# API Access
resource "aws_security_group_rule" "api_access" {
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
  security_group_id        = aws_security_group.controller.id
}

resource "aws_security_group_rule" "api_egress_access" {
  type                     = "egress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.controller.id
  security_group_id        = aws_security_group.lb.id
}

resource "aws_security_group_rule" "lb_https_access" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "lb_http_redirect_access" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "lb_access_for_me" {
  type              = "ingress"
  from_port         = 9200
  to_port           = 9200
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.controller.id
}

# Controller Access from Worker
resource "aws_security_group_rule" "controller_access" {
  type                     = "ingress"
  from_port                = 9201
  to_port                  = 9201
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.controller.id
}

resource "aws_security_group_rule" "external_worker_controller_access" {
  type              = "ingress"
  from_port         = 9201
  to_port           = 9201
  protocol          = "tcp"
  security_group_id = aws_security_group.controller.id
  cidr_blocks       = ["27.32.248.192/32"]
}

resource "aws_security_group_rule" "worker_access" {
  type              = "ingress"
  from_port         = 9202
  to_port           = 9202
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker.id
}

### RDS Access from Controller
resource "aws_security_group_rule" "controller_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.controller.id
}
