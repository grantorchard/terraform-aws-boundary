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

# Boundary external access
resource "aws_security_group_rule" "lb_https_access" {
  type              = "ingress"
  from_port         = var.api_lb_port
  to_port           = var.api_lb_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb.id
}

# Permit access on 80, which we redirect
resource "aws_security_group_rule" "lb_http_redirect_access" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb.id
}

# API ingress rule applied to controllers
resource "aws_security_group_rule" "api_ingress_access" {
  type                     = "ingress"
  from_port                = var.api_port
  to_port                  = var.api_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
  security_group_id        = aws_security_group.controller.id
}

# API egress rule applied to lb, don't let the source_security_group fool you!
resource "aws_security_group_rule" "api_lb_egress_access" {
  type                     = "egress"
  from_port                = var.api_port
  to_port                  = var.api_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.controller.id
  security_group_id        = aws_security_group.lb.id
}

# resource "aws_security_group_rule" "cluster_lb_egress_access" {
#   type                     = "egress"
#   from_port                = var.cluster_port
#   to_port                  = var.cluster_port
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.controller.id
#   security_group_id        = aws_security_group.contoller_cluster_lb.id
# }

# Controller Access from Worker
resource "aws_security_group_rule" "controller_ingress_access" {
  type                     = "ingress"
  from_port                = var.cluster_port
  to_port                  = var.cluster_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.controller
  cidr_blocks       = ["0.0.0.0/0"]
}

# Remote client to worker access
resource "aws_security_group_rule" "worker_ingress_access" {
  type              = "ingress"
  from_port         = var.worker_port
  to_port           = var.worker_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker.id
}

# RDS Access from Controller
resource "aws_security_group_rule" "controller_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.controller.id
}

# Vault access to RDS for dynamic credential management
resource "aws_security_group_rule" "hcp_to_rds" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = ["172.25.16.0/20"]
}
