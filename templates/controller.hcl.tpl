#!/bin/bash
hostname=$(hostname)
ip_address=$(ip -j addr | jq -r '.[] | select(.ifname=="eth0") | .addr_info[] | select(.family=="inet") | .local')

#Generate config file
cat <<EOH > /etc/boundary.d/config.hcl
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
EOH

BOUNDARY_INIT=$(boundary database init -skip-auth-method-creation -skip-host-resources-creation -skip-scopes-creation -skip-target-creation -config /etc/boundary.d/config.hcl || true)
echo $BOUNDARY_INIT | sudo tee -a /etc/boundary.d/init.log

# Finish service configuration for boundary and start the service
sudo chown -R boundary:boundary /etc/boundary.d/config.hcl
sudo systemctl daemon-reload
sudo systemctl enable boundary.service
sudo systemctl start boundary.service