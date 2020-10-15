data template_file "userdata" {
  template = file("${path.module}/templates/userdata.yaml")

  vars = {
    boundary_conf       = base64encode(templatefile("${path.module}/templates/config.hcl.tmpl",
      {
          hostname = var.hostname
          domain = data.aws_route53_zone.this.name
          kms_root   = aws_kms_key.root.id
          kms_worker_auth = aws_kms_key.worker-auth.id
          kms_recovery = aws_kms_key.recovery.id
      }
    ))
  }
}