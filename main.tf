provider "aws" {
  region = "us-west-2"
}

#VPC
resource "aws_vpc" "project_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Project VPC"
  }
}

#puplic subnet
resource "aws_subnet" "project-public-subnet" {
  vpc_id = aws_vpc.project_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "Public Subnet"
  }
}

#Internet Gateway for public subnet
resource "aws_internet_gateway" "inter_gw" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

#Routing table
resource "aws_route_table" "project-public-rt" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inter_gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.inter_gw.id
  }

  tags = {
    Name = "Project Route Table"
  }
}

#Associations 
resource "aws_route_table_association" "public-RT" {
  subnet_id = aws_subnet.project-public-subnet.id
  route_table_id = aws_route_table.project-public-rt.id
}

#Security Groups
resource "aws_security_group" "project_sg" {
  name = "HTTP and SSH"
  vpc_id = aws_vpc.project_vpc.id

  ingress { #inbound
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { #inbound
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { #connect public ip
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_instance" {
  ami = "ami-0533f2ba8a1995cf9"
  instance_type = "t2.nano"
  key_name = "MyKeyPair2"

  subnet_id = aws_subnet.project-public-subnet.id
  vpc_security_group_ids = [aws_security_group.project_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash -ex

  amazon-linux-extras install nginx1 -y
  echo "<h1>$(curl https://api.kanye.rest/?format=text)</h1>" >  /usr/share/nginx/html/index.html 
  systemctl enable nginx
  systemctl start nginx
  EOF

  tags = {
    "Name" : "nginx server"
  }
}