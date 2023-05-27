# Generate, Store and Retrieve Password Using SSM Parameter Store

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

resource "aws_db_instance" "prod" {
  identifier           = "prod-mysql-rds"
  allocated_storage    = 20
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = data.aws_secretsmanager_secret_version.rds_password.secret_string
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  apply_immediately    = true
}
#Generat Password
resource "random_password" "db_prod" {
  length           = 20
  special          = true
  override_special = "!#()"

}
// Store Password
resource "aws_secretsmanager_secret" "rds_password" {
  name                    = "/prod/rds/password"
  description             = "Password for my RDS DataBase"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.db_prod.result
}

// Store Password
resource "aws_secretsmanager_secret" "rds_all" {
  name                    = "/prod/rds/all"
  description             = "Password for my RDS DataBase"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_all" {
  secret_id = aws_secretsmanager_secret.rds_all.id
  secret_string = jsonencode({
    rds_secret = random_password.db_prod.result
    rds_port   = aws_db_instance.prod.port
    username   = aws_db_instance.prod.username
  })
}

// Retrieve Password
data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id  = aws_secretsmanager_secret.rds_password.id
  depends_on = [aws_secretsmanager_secret_version.rds_password]
}

data "aws_secretsmanager_secret_version" "rds_all" {
  secret_id  = aws_secretsmanager_secret.rds_all.id
  depends_on = [aws_secretsmanager_secret_version.rds_all]
}







// Store password
/* resource "aws_ssm_parameter" "rds_password" {
  name        = "/prod/prod-mysql-rds/password"
  description = "password for prod db"
  type        = "SecureString"
  value       = random_password.db_prod.result
}
#Retrieve Password
data "aws_ssm_parameter" "rds_password" {
  name       = "/prod/prod-mysql-rds/password"
  depends_on = [aws_ssm_parameter.rds_password]
} */

#!--------------
output "rds_endpoint" {
  value = aws_db_instance.prod.endpoint
}
output "rds_port" {
  value = aws_db_instance.prod.port
}
output "rds_password" {
  sensitive = true
  value     = data.aws_secretsmanager_secret_version.rds_password.secret_string
}
output "rds_all" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.rds_all.secret_string)
  sensitive = true

}
