
resource "aws_db_instance" "this" {
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "postgres"
  engine_version      = "11.12"
  instance_class      = "db.m6g.16xlarge"
  name                = var.database_name
  username            = var.database_username
  password            = var.database_password
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  publicly_accessible    = false

}

resource "aws_db_subnet_group" "this" {
  name       = "boundary"
  subnet_ids = data.terraform_remote_state.this.outputs.private_subnets
}
