# Load subnet
data "aws_subnet" "subnet" {
  filter {
    name   = "tag:Name"
    values = [var.subnet_name]
  }
}

# Load latest AMI of Amazon Linux 2023
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

# Create security group for EC2 Instances
resource "aws_security_group" "sg" {
  name        = var.security_group_name
  vpc_id      = data.aws_subnet.subnet.vpc_id
  
  tags = {
    Name = var.security_group_name
  }
}

# Allow SSH inbound
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = var.control_node_ip
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# Allow HTTPS outbound
resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# Create key_pair for EC2 Instances
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  private_key_file = "./ec2-user.pem"
}

resource "local_file" "private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.key_pair.private_key_pem
  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_file}"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "ec2-user"
  public_key = tls_private_key.key_pair.public_key_openssh
}

# Create EC2 Instances
resource "aws_instance" "ec2" {
  for_each      = toset(var.ec2_names)
  ami           = var.ami_id == null ? data.aws_ami.al2023.id : var.ami_id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key_pair.key_name
  subnet_id     = data.aws_subnet.subnet.id

  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = var.associate_public_ip_address

  tags = {
    Name = each.value
  }
}

output "ec2_public_ip" {
  value = {for k, v in aws_instance.ec2 : k => v.public_ip}
}

output "ec2_private_ip" {
  value = {for k, v in aws_instance.ec2 : k => v.private_ip}
}