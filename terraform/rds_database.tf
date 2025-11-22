resource "aws_db_subnet_group" "fuji" {
  name       = "fuji-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_db_a.id, aws_subnet.private_subnet_db_b.id]
  tags = {
    Name = "fuji-db-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow Postgres from ECS tasks"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
   cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_db_instance" "fuji" {
  identifier              = "fuji-db"
  engine                  = "postgres"
  engine_version          = "17"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_name                 = var.SERVICE_DB_NAME
  username                = var.SERVICE_DB_LOGIN
  password                = var.SERVICE_DB_PASSWORD
  parameter_group_name    = "default.postgres17"
  skip_final_snapshot     = true                # lub false + final snapshot
  multi_az                = false               # taniej
  storage_encrypted       = true
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.fuji.name
  tags = {
    Name = "fuji-db"
  }
}
