#!/bin/bash
hostname=$(hostname)
ip_address=$(ip -j addr | jq -r '.[] | select(.ifname=="eth0") | .addr_info[] | select(.family=="inet") | .local')

#Generate config file
cat <<EOF > /etc/boundary.d/config.hcl
${boundary_conf}
EOF

# Make sure to initialize the DB before starting the service. This will result in
# a database already initizalized warning if another controller or worker has done this
# already, making it a lazy, best effort initialization
%{ if role == "controller" }
BOUNDARY_INIT=$(boundary database init -skip-auth-method-creation -skip-host-resources-creation -skip-scopes-creation -skip-target-creation -config /etc/boundary.d/config.hcl || true)
echo $BOUNDARY_INIT | sudo tee -a /etc/boundary.d/init.log
%{ endif }

# Finish service configuration for boundary and start the service
sudo chown -R boundary:boundary /etc/boundary.d/config.hcl
sudo systemctl daemon-reload
sudo systemctl enable boundary.service
sudo systemctl start boundary.service


# write_files:
#   - path: /etc/boundary.d/config.hcl
#     content: ${boundary_conf}
#     permissions: '0644'
#     owner: boundary:boundary
#     encoding: b64

# runcmd:
#   - IP_ADDRESS=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
#   - sed 
#   - BOUNDARY_INIT=$(sudo boundary database init -skip-host-resources-creation -skip-scopes-creation -skip-target-creation -config /etc/boundary.d/config.hcl || true)
#   - echo $BOUNDARY_INIT | sudo tee -a /etc/boundary.d/init.log
#   - sudo systemctl enable boundary
#   - sudo systemctl restart boundary