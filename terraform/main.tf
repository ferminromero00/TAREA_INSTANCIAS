provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# Crea una VPC con una subred pública y privada
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "ExampleVPC" }
}

resource "aws_subnet" "public_subnet" {  
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "PublicSubnet" }
}

resource "aws_subnet" "private_subnet" { 
  vpc_id = aws_vpc.example.id
  cidr_block = "10.0.2.0/24"
  tags = { Name = "PrivateSubnet" }
}

# Crea un gateway de internet y lo asocia a la VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.example.id
  tags = { Name = "ExampleIGW" }
}

# Crea una tabla de rutas para la subred pública y la asocia al gateway de internet
resource "aws_route_table" "public_route_table" {  
  vpc_id = aws_vpc.example.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "PublicRouteTable" }
}

# Asocia la subred pública a la tabla de rutas pública
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Crea una Elastic IP y un NAT Gateway para la subred privada
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = { Name = "NATGateway" }
}

# Crea una tabla de rutas para la subred privada y la asocia al NAT Gateway
resource "aws_route_table" "private_route_table" {  
  vpc_id = aws_vpc.example.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = { Name = "PrivateRouteTable" }
}

# Asocia la subred privada a la tabla de rutas privada
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# Crea el par de claves SSH para la instancia
resource "aws_key_pair" "nginx-server-ssh" {
  key_name   = "nginx-server-ssh"
  public_key = file("nginx-server.key.pub")
  tags       = { Name = "nginx-server-ssh" }
}

# Grupo de seguridad para permitir acceso SSH y HTTP
resource "aws_security_group" "nginx-server-sg" {
  vpc_id      = aws_vpc.example.id
  name        = "nginx-server-sg"
  description = "Grupo de seguridad, permitiendo el acceso de SSH y HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Grupo_de_Seguridad" }
}

# Crea una instancia en la subred pública dentro de la VPC
resource "aws_instance" "ubuntu" {
    ami                    = "ami-0866a3c8686eaeeba"
    instance_type          = "t2.micro"

    network_interface { 
        network_interface_id = aws_network_interface.nginx-interface.id
        device_index = 0
    }

    key_name               = aws_key_pair.nginx-server-ssh.key_name

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx
  EOF

  tags = { Name = "nginx-server" }
}

# Crear una interfaz para la instancia
resource "aws_network_interface" "nginx-interface" {
  subnet_id       = aws_subnet.public_subnet.id 
  private_ips     = ["10.0.1.10"]
  security_groups  = [aws_security_group.nginx-server-sg.id]  

  tags = { Name = "network_interface" }
}