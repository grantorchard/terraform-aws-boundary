


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