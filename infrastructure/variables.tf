variable "aws_region" {
    default = "us-east-1"
}

variable "myip" {
    default = "200.192.99.70"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "public-subnet_cidr" {
    type = list
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private-subnet_cidr" {
    type = list
    default = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24", "10.0.14.0/24", "10.0.15.0/24"]
}

variable "availability_zone" {
    type = list
    default = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
}

variable "iamrole-name" {
    default = "webapp-task-execution-role"
}

variable "db-engine" {
    default = "postgres"
}

variable "db-name" {
    default = "lojaonline"
}

variable "db-username" {
    default = "postgres"
}

variable "db-password" {
    default = "Csr3q9dwnRrZiSS"
}

variable "db-engine-version" {
    default = "14.1"
}

variable "db-instance-class" {
    default = "db.t3.micro"
}

variable "container_image" {
    default = "114368227931.dkr.ecr.us-east-1.amazonaws.com/webapp:latest"
}