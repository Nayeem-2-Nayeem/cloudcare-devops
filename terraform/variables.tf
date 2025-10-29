variable "aws_region" { default = "us-east-2" }
variable "key_name" {}
variable "instance_type" { default = "t2.micro" }
variable "db_username" { default = "clouduser" }
variable "db_password" { description = "RDS password" }
