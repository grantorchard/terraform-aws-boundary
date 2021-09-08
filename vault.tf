resource "vault_database_secret_backend_connection" "this" {
  backend       = local.vault_db_path
  name          = var.vault_database_connection_name
  allowed_roles = ["boundary"]

  postgresql {
    connection_url = "postgres://${var.database_username}:${var.database_password}@${aws_db_instance.this.endpoint}/${var.database_name}"
  }
}

resource "vault_database_secret_backend_role" "this" {
  backend = local.vault_db_path
  name    = "boundary"
  db_name = vault_database_secret_backend_connection.this.name
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT rds_superuser TO \"{{name}}\"; GRANT ALL PRIVILEGES ON DATABASE ${var.database_name} TO \"{{name}}\";"
  ]
}


# resource "vault_generic_endpoint" "rotate" {
#   depends_on           = [
# 		vault_database_secret_backend_connection.postgres]
#   path                 = "database/rotate-root/${vault_database_secret_backend_connection.this.name}"
#   disable_read   = true
#   disable_delete = true

#   data_json = "{}"
# }

# 