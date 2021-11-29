variable "key_name" {
  type    = string
  default = "go"
}

variable "lb_hostname" {
  type    = string
  default = "boundary"
}

variable "worker_lb_hostname" {
  type    = string
  default = "workers"
}

variable "cluster_lb_hostname" {
  type    = string
  default = "cluster"
}

variable "instance_profile_path" {
  description = "Path in which to create the IAM instance profile."
  default     = "/"
}

variable "domain" {
  type    = string
  default = "go.hashidemos.io"
}

variable "cluster_port" {
  type    = number
  default = 9201
}

variable "cluster_lb_port" {
  type    = number
  default = 9201
}

variable "api_port" {
  type    = number
  default = 9200
}

variable "api_lb_port" {
  type    = number
  default = 443
}

variable "worker_port" {
  type    = number
  default = 9202
}

variable "worker_lb_port" {
  type    = number
  default = 9202
}

variable "database_username" {
  type    = string
  default = "boundary"
}

variable "database_password" {
  type    = string
  default = "boundary"
}

variable "database_name" {
  type    = string
  default = "boundary"
}

variable "tls_disabled" {
  type    = bool
  default = true
}

variable "tls_cert_path" {
  type    = string
  default = "/etc/boundary.d/certs/"
}

variable "controller_size" {
  type    = string
  default = "t2.micro"
}

variable "worker_size" {
  type    = string
  default = "t2.micro"
}

variable "vault_database_connection_name" {
  type    = string
  default = "boundary"
}

# Variables for default_tags variable set
variable "owner" {
	type = string
}

variable "se-region" {
	type = string
}

variable "purpose" {
	type = string
}

variable "ttl" {
	type = number
}

variable "terraform" {
	type = bool
}

variable "hc-internet-facing" {
	type = bool
}