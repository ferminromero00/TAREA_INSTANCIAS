# Configuración del proveedor AWS
provider "aws" {
    region  = "us-east-1"  
    profile = "default"   
}

# Creacion de la instancia, conectando la clave ssh publica y privada,  uniendo el grupo de seguridad

resource "aws_instance" "ubuntu" {
    ami = "ami-0866a3c8686eaeeba"
    instance_type = "t2.micro"

    user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx
    EOF

    key_name = aws_key_pair.nginx-server-ssh.key_name
    vpc_security_group_ids = [aws_security_group.nginx-server-sg.id]

}
#COMANDO PARA CREAR CLAVES: ssh-keygen -t rsa -b 2048 -f "nginx-server.key"
resource "aws_key_pair" "nginx-server-ssh" {
    key_name = "nginx-server-ssh"
    public_key = file("nginx-server.key.pub")
}

# GRUPO DE SEGURIDAD
resource "aws_security_group" "nginx-server-sg" {
    name = "nginx-server-sg"
    description = "Grupo de seguridad, permitiendo el acceso de SSH y HTTP"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}









