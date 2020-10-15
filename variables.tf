variable tags {
  type = map
  default = {
    TTL   = "48"
    owner = "Grant Orchard"
  }
}

variable instance_type {
  type    = string
  default = "t2.medium"
}

variable key_name {
  type    = string
  default = "go"
}