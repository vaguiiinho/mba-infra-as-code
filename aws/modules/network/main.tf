resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    "Name" = "${var.prefix}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnets" {
  # count             = length(var.subnet_cidr_blocks)
  for_each = toset(var.subnet_cidr_blocks)
  vpc_id   = aws_vpc.vpc.id
  # cidr_block        = var.subnet_cidr_blocks[count.index]
  cidr_block = each.key
  # availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    "Name" = "${var.prefix}-subnet-${each.key}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "association" {
  # count          = length(var.subnet_cidr_blocks)
  for_each       = toset(var.subnet_cidr_blocks)
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "${var.prefix}Allow SSH"

  tags = {
    name = "${var.prefix}Allow SSH"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_ssh_ingress_rule" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "sg_http_ingress_rule" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "sg_egress_rule" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
