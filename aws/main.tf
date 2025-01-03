terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.2"
    }
  }
}

data "aws_secretsmanager_secret" "secret" {
  arn = "arn:aws:secretsmanager:us-west-2:859066267568:secret:prod/TerraformTest-SxUEHP"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secret.id
}

provider "aws" {
  region  = "us-west-2"
  profile = "default"
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example_subnet" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_instance" "example_instance" {
  ami           = "ami-07d9cf938edb0739b"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.example_subnet.id

  user_data = <<EOF
  #!/bin/bash
  DB_STRING="Serve=${jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["Host"]}; DB=${jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["Db"]}"
  echo $DB_STRING > test.txt
  EOF
}

resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id
}

resource "aws_eip" "example_ip" {
  instance   = aws_instance.example_instance.id
  depends_on = [aws_internet_gateway.example_igw]
}

resource "aws_ssm_parameter" "parameter" {
  name  = "mv_ip"
  type  = "String"
  value = aws_eip.example_ip.public_ip
}

output "private_dns" {
  value = aws_instance.example_instance.private_dns
}

output "eip" {
  value = aws_eip.example_ip.public_ip
}
