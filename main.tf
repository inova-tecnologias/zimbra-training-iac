provider "aws" {
    region  = var.region
}

locals {
  tags = {
    Project = var.customer_name
    Training = true
  }
}

#----------------NETWORKING---------------#
resource "aws_vpc" "vpc_training" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
      var.tags,
      local.tags
  )
}

resource "aws_subnet" "sn_training" {
  vpc_id     = aws_vpc.vpc_training.id
  cidr_block = "10.0.0.0/24"

  tags = merge(
      var.tags,
      local.tags
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_training.id

  tags = merge(
      var.tags,
      local.tags
  )
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.vpc_training.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    local.tags
  )
}

resource "aws_main_route_table_association" "arta" {
  vpc_id = aws_vpc.vpc_training.id
  route_table_id = aws_route_table.r.id
}
#-----------------------------------------#

#-----------------SECURITY----------------#
resource "aws_security_group" "sc_training" {
  name        = "training"
  description = "Allow ports needed on zimbra training"
  vpc_id      = aws_vpc.vpc_training.id
  tags = merge(
    var.tags,
    local.tags
  )
}

resource "aws_security_group_rule" "enableports" {
  count             = length(var.zports)
  type              = "ingress"
  from_port         = var.zports[count.index]
  to_port           = var.zports[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sc_training.id
}

resource "tls_private_key" "training_pem" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "training_pem" {
  key_name   = "trainingkey.pem"
  public_key = tls_private_key.training_pem.public_key_openssh
}

#-----------------------------------------#

#----------NET-INTERFACES-AND-IPS---------#

resource "aws_network_interface" "training_interfaces" {
  count           = var.participants*2
  security_groups = [aws_security_group.sc_training.id]
  subnet_id       = aws_subnet.sn_training.id
  
  tags = merge(
    var.tags,
    local.tags
  )
}

resource "aws_eip" "training_ips" {
  count             = var.participants*2
  vpc               = true
  network_interface = element(aws_network_interface.training_interfaces.*.id, count.index)

  tags = merge(
    var.tags,
    local.tags
  )
}
#-----------------------------------------#

#-------------------DNS-------------------#
resource "aws_route53_zone" "training_zone" {
  name = var.training_zone

  tags = merge(
    var.tags,
    local.tags
  )
}

resource "aws_route53_zone" "training_zone_private" {
  name   = var.training_zone
  vpc {
    vpc_id = aws_vpc.vpc_training.id
  }
  
  tags = merge(
    var.tags,
    local.tags
  )
}

resource "aws_route53_record" "record_vm1" {
  count   = var.participants
  zone_id = aws_route53_zone.training_zone.zone_id
  name    = "vm1.zimbra${count.index}"
  type    = "A"
  ttl     = "300"
  records = [element(aws_eip.training_ips.*.public_ip, count.index)]
}

resource "aws_route53_record" "record_vm2" {
  count   = var.participants
  zone_id = aws_route53_zone.training_zone.zone_id
  name    = "vm2.zimbra${count.index}"
  type    = "A"
  ttl     = "300"
  records = [element(aws_eip.training_ips.*.public_ip, count.index + var.participants)]
}

resource "aws_route53_record" "record_vm1_private" {
  count   = var.participants
  zone_id = aws_route53_zone.training_zone_private.zone_id
  name    = "vm1.zimbra${count.index}"
  type    = "A"
  ttl     = "300"
  records = [element(aws_eip.training_ips.*.private_ip, count.index)]
}

resource "aws_route53_record" "record_vm2_private" {
  count   = var.participants
  zone_id = aws_route53_zone.training_zone_private.zone_id
  name    = "vm2.zimbra${count.index}"
  type    = "A"
  ttl     = "300"
  records = [element(aws_eip.training_ips.*.private_ip, count.index + var.participants)]
}
#-----------------------------------------#
#-------------------VM1-------------------#
resource "aws_instance" "ec2_vm1" {
  count         = var.vm1 ? var.participants : 0
  ami           = var.instance.ami
  instance_type = var.instance.type
  key_name      = aws_key_pair.training_pem.key_name
  network_interface {
    network_interface_id = element(aws_network_interface.training_interfaces.*.id, count.index)
    device_index         = 0
  }

  tags = merge(
    var.tags,
    local.tags,
    {
      "Name" = "vm1.zimbra${count.index}"
    }
  )
}
#-------------------VM2-------------------#
resource "aws_instance" "ec2_vm2" {
  count         = var.vm2 ? var.participants : 0
  ami           = var.instance.ami
  instance_type = var.instance.type
  key_name      = aws_key_pair.training_pem.key_name
  network_interface {
    network_interface_id = element(aws_network_interface.training_interfaces.*.id, count.index + var.participants)
    device_index         = 0
  }
  tags = merge(
    var.tags,
    local.tags,
    {
      "Name" = "vm2.zimbra${count.index}"
    }
  )
}