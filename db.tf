resource "aws_db_instance" "cesi-db" {
  allocated_storage      = 10
  db_name                = "cesidb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "cesi"
  password               = random_password.dbpassword.result
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.cesi-db-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.cesi-db-sn.id

  tags = {
    Name = "cesidb"
  }
}

resource "random_password" "dbpassword" {
  length           = 16
  special          = true
  override_special = "_%@"
}
