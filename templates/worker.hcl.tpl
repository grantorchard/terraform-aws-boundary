#!/bin/bash
hostname=$(hostname)
ip_address=$(ip -j addr | jq -r '.[] | select(.ifname=="eth0") | .addr_info[] | select(.family=="inet") | .local')

#Generate config file
cat <<EOH > /etc/boundary.d/config.hcl
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
	public_addr = "${worker_lb_fqdn}:${worker_lb_port}"
	name = "$hostname"
	controllers = [
		"${cluster_lb_fqdn}:${cluster_lb_port}"
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
EOH

# Finish service configuration for boundary and start the service
sudo chown -R boundary:boundary /etc/boundary.d/config.hcl
sudo systemctl daemon-reload
sudo systemctl enable boundary.service
sudo systemctl start boundary.service

