disable_mlock = true

telemetry {
  prometheus_retention_time = "24h"
  disable_hostname          = true
}

controller {
  name        = "$hostname"
  description = "A controller for a demo!"

  database {
    url = "postgresql://${database_username}:${database_password}@${database_endpoint}/${database_name}"
  }
	public_cluster_addr = "${cluster_lb_fqdn}"
}

listener "tcp" {
  address       = "$ip_address:${api_port}"
	purpose       = "api"
%{ if tls_disabled == true }
	tls_disable   = true
%{ else }
  tls_disable   = false
  tls_cert_file = "${tls_cert_path}/api/cert.crt"
  tls_key_file  = "${tls_cert_path}/api/cert.key"
%{ endif }
	cors_enabled         = true
	cors_allowed_origins = ["*"]
}

listener "tcp" {
  address = "$ip_address:${cluster_port}"
	purpose = "cluster"
%{ if tls_disabled == true }
	tls_disable = true
%{ else }
  tls_disable   = false
  tls_cert_file = "${tls_cert_path}/controller/cert.crt"
  tls_key_file  = "${tls_cert_path}/controller/cert.key"
%{ endif }
}

kms "awskms" {
  purpose    = "root"
  kms_key_id = "${kms_root}"
}

kms "awskms" {
  purpose    = "worker-auth"
  kms_key_id = "${kms_worker_auth}"
}

kms "awskms" {
  purpose    = "recovery"
  kms_key_id = "${kms_recovery}"
}