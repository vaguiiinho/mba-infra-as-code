data "aws_secretsmanager_secret" "secret" {
  arn = "arn:aws:secretsmanager:us-west-2:859066267568:secret:prod/TerraformTest2-GQLrow"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secret.id
}

resource "aws_instance" "instances" {
  count                  = var.instance_count
  ami                    = "ami-07d9cf938edb0739b"
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  user_data = <<EOF
  #!/bin/bash
  DB_STRING="Server=${jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["Host"]};DB=${jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["DB"]}"
  echo $DB_STRING > test.txt
  EOF

  tags = {
    Name = "${var.prefix}-node-${count.index}"
  }
}

# resource "aws_eip" "example_ip" {
#   instance   = aws_instance.example_instance.id
#   depends_on = [aws_internet_gateway.example_igw]
# }

# resource "aws_ssm_parameter" "parameter" {
#   name  = "mv_ip"
#   type  = "String"
#   value = aws_eip.example_ip.public_ip
# }
