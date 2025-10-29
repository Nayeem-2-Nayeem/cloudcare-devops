data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "web_sg" {
  name        = "cloudcare-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0d9a665f802ae6227"
  instance_type          = "t2.micro"
  key_name               = "dy"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = data.aws_subnets.default.ids[0]

  tags = {
    Name = "cloudcare-web"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "cloudcare-subnet-group"
  subnet_ids = slice(data.aws_subnets.default.ids, 0, 2)
}

resource "aws_db_instance" "db" {
  identifier             = "cloudcare-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  db_name                = "cloudcare"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
}

resource "aws_s3_bucket" "assets" {
  bucket = "cloudcare-assets-${random_id.id.hex}"
  acl    = "private"
}

resource "random_id" "id" {
  byte_length = 4
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.db.address
}
