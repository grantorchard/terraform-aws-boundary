data "template_file" "controller_userdata" {
  template = file("${path.module}/templates/userdata.yaml.tpl")

  vars = {
    role = "controller"
    boundary_conf = templatefile("${path.module}/templates/controller.hcl.tpl",
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
    )
  }
}


data "template_file" "worker_userdata" {
  template = file("${path.module}/templates/userdata.yaml.tpl")

  vars = {
    role = "worker"
    boundary_conf = templatefile("${path.module}/templates/worker.hcl.tpl",
      {
        worker_port     = var.worker_port
        worker_lb_fqdn  = "${var.lb_hostname}.${data.aws_route53_zone.this.name}"
        worker_lb_port  = var.worker_lb_port
        tls_cert_path   = var.tls_cert_path
        kms_root        = aws_kms_key.root.id
        kms_worker_auth = aws_kms_key.worker_auth.id
        kms_recovery    = aws_kms_key.recovery.id
        tls_disabled    = var.tls_disabled
        tls_cert_path   = var.tls_cert_path
      }
    )
  }
}