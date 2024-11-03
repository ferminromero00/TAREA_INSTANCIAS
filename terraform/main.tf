# Declaración de variables
variable "region" {
  default = "us-east-1"  # Puedes definir la región que necesites
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_session_token" {}

# Configuración del proveedor AWS
provider "aws" {
  region      = var.region
  access_key  = var.aws_access_key
  secret_key  = var.aws_secret_key
  token       = var.aws_session_token
}

# Crea una VPC con una subred pública y privada
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "ExampleVPC" }
}

resource "aws_subnet" "public_subnet" {  
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "PublicSubnet" }
}

resource "aws_subnet" "private_subnet" { 
  vpc_id     = aws_vpc.example.id
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
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = aws_nat_gateway.nat_gateway.id
  }
  tags = { Name = "PrivateRouteTable" }
}

# Asocia la subred privada a la tabla de rutas privada
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
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

# Crea un bucket S3 con un nombre único
resource "aws_s3_bucket" "bucket_web" {
  bucket = "bucket-web-fermin-unique-string"  
}

# Configuración de bloqueos de acceso público
resource "aws_s3_bucket_public_access_block" "bucket_web_access_block" {
  bucket = aws_s3_bucket.bucket_web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Política de acceso al bucket para permitir la lectura pública
resource "aws_s3_bucket_policy" "bucket_web_policy" {
  bucket = aws_s3_bucket.bucket_web.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.bucket_web.arn}/*"
    }
  ]
}
EOF
}

# Carga el archivo ZIP en el bucket S3
resource "aws_s3_object" "project_zip" {
  bucket = aws_s3_bucket.bucket_web.bucket
  key    = "project.zip"
  source = "../Web/project.zip"  # Ruta local al archivo ZIP
}

# Crea una instancia en la subred pública dentro de la VPC
resource "aws_instance" "ubuntu" {
  ami                    = "ami-0866a3c8686eaeeba"
  instance_type          = "t2.micro"

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx

    cd /var/www/html
    sudo rm index.nginx-debian.html
    sudo apt-get install wget -y

    wget https://bucket-web-fermin-unique-string.s3.us-east-1.amazonaws.com/project.zip
    sudo apt install unzip
    unzip -o project.zip
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
