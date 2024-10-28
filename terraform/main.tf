provider "aws" {
  region = "us-east-1" # Change this to your preferred region
}

resource "aws_instance" "app_server" {
  ami           = "ami-0cff7528ff583bf9a" # Amazon Linux 2 AMI
  instance_type = "t2.medium"
  key_name      = aws_key_pair.clo835_key_pair.key_name # Replace with your key pair name

  vpc_security_group_ids = [aws_security_group.allow_web.id]

  tags = {
    Name = "CLO835-Assignment2-EC2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              EOF
}

resource "aws_key_pair" "clo835_key_pair" {
  key_name   = "clo835_key_pair"             # Name of the key pair in AWS
  public_key = file("~/.ssh/clo835_key.pub") # Path to the public key file
}


resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow inbound web traffic"

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow NodePort range for K8s"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s_security_group"
  }
}

resource "aws_ecr_repository" "webapp" {
  name = "clo835-assignment2-webapp"
}

resource "aws_ecr_repository" "mysql" {
  name = "clo835-assignment2-mysql"
}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "webapp_ecr_repository_url" {
  value = aws_ecr_repository.webapp.repository_url
}

output "mysql_ecr_repository_url" {
  value = aws_ecr_repository.mysql.repository_url
}