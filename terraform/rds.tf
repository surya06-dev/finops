provider "aws" {
  region = "us-east-1"
}

############################
# Get Default VPC
############################

data "aws_vpc" "default" {
  default = true
}

############################
# Get Subnets from VPC
############################

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

############################
# Security Group for RDS
############################

resource "aws_security_group" "rds_sg" {
  name        = "infracost-rds-sg"
  description = "Security group for RDS test"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "infracost-rds-sg"
  }
}

############################
# Subnet Group for RDS
############################

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "infracost-rds-subnet-group"
  subnet_ids = data.aws_subnets.default_subnets.ids

  tags = {
    Name = "infracost-rds-subnet-group"
  }
}

############################
# Parameter Group
############################

resource "aws_db_parameter_group" "rds_param_group" {
  name   = "infracost-rds-params"
  family = "mysql5.7"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  tags = {
    Name = "infracost-rds-parameter-group"
  }
}

############################
# RDS Instance
############################

resource "aws_db_instance" "infracost_rds_test" {
  identifier             = "infracost-rds-test-db"

  engine                 = "mysql"
  engine_version         = "5.7"   # <-- This triggers the campaign
  instance_class         = "db.t3.large"

  allocated_storage      = 20
  storage_type           = "gp2"

  username               = "admin"
  password               = "MySQl25#"

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible    = false
  skip_final_snapshot    = true

  backup_retention_period = 7
  monitoring_interval     = 60

  tags = {
    Name        = "infracost-rds"
    Environment = "dev"
    Project     = "infracost-testing"
  }
}