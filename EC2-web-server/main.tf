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
resource "aws_default_vpc" "default" {}

resource "aws_eip" "lb" {
  instance = aws_instance.test.id
  vpc      = true
  tags = {
    Name  = "webserver built by Teraaform"
    Owner = "Daniel Kotev"
  }
}

resource "aws_instance" "test" {
  ami                         = "ami-03aefa83246f44ef2"
  vpc_security_group_ids      = [aws_security_group.web.id]
  instance_type               = "t2.micro"
  user_data                   = file("user_data.sh")
  user_data_replace_on_change = true
  tags = {
    Name  = "webserver built by Teraaform"
    Owner = "Daniel Kotev"
  }

  lifecycle {
    create_before_destroy = true

  }
}

resource "aws_security_group" "web" {
  name        = "web-SG"
  description = "security group for my webserver"
  vpc_id      = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      description = "Allow port Http"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Allow all ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "webserver built by Teraaform"
    Owner = "Daniel Kotev"
  }

}
