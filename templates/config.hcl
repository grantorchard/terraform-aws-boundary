disable_mlock = true


controller {
  name = "demo-controller-1"
  description = "A controller for a demo!"

  database {
      url = "postgresql://boundary:boundary@127.0.0.1/boundary"
  }
}

worker {
  name = "example-worker"
  description = "An example worker"
  public_addr = "${hostname}${domain}"

}

listener "tcp" {
  address = "0.0.0.0:9200"
  purpose = "api"

  tls_disable = true
  cors_enabled = false
  cors_allowed_origins = ["${domain}"]
}

listener "tcp" {
  address = "127.0.0.1:9201"
  purpose = "cluster"

  tls_disable = true
}

listener "tcp" {
    purpose = "proxy"
    tls_disable = true
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