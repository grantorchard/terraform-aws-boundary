listener "tcp" {
  address = "$ip_address:${worker_port}"
	purpose = "proxy"
%{ if tls_disabled == true }
	tls_disable = true
%{ else }
  tls_disable   = false
  tls_cert_file = "${tls_cert_path}/worker.crt"
  tls_key_file  = "${tls_cert_path}/worker.key"
%{ endif }
}

worker {
	public_addr = "${worker_lb_fqdn}"
	name = "$(hostname)"
	controllers = [
		"${worker_lb_fqdn}:${worker_lb_port}"
  ]
}

kms "awskms" {
  purpose = "root"
  kms_key_id = "${kms_root}"
}

kms "awskms" {
  purpose = "worker-auth"
  kms_key_id = "${kms_worker_auth}"
}

kms "awskms" {
  purpose = "recovery"
  kms_key_id = "${kms_recovery}"
}


