##############################################
# NETWORK
##############################################

# VPC
resource "aws_vpc" "vpc-webapp" {
   cidr_block = var.vpc_cidr
   enable_dns_hostnames = true
   enable_dns_support = true

   tags = {
     Name = "VPC-Webapp"
     Ambiente = "Medcloud-challenge"
   }
}

resource "aws_internet_gateway" "igw-vpc1" {
  vpc_id = aws_vpc.vpc-webapp.id
}

# SUBNET
resource "aws_subnet" "public-subnet" {
    count = "${length(var.public-subnet_cidr)}"
    cidr_block = element(var.public-subnet_cidr,count.index)
    availability_zone = element(var.availability_zone,count.index)
    vpc_id = aws_vpc.vpc-webapp.id
    tags = {
        Ambiente = "Medcloud-challenge"
        name = "Subnet-public-${count.index+1}"
    }
}

resource "aws_subnet" "private-subnet" {
    count = "${length(var.private-subnet_cidr)}"
    cidr_block = element(var.private-subnet_cidr,count.index)
    availability_zone = element(var.availability_zone,count.index)
    vpc_id = aws_vpc.vpc-webapp.id
    tags = {
        Ambiente = "Medcloud-challenge"
        name = "Subnet-private-${count.index+1}"
    }
}

# ROUTE TABLE
resource "aws_route_table" "rtb-webapp-public" {
    vpc_id = aws_vpc.vpc-webapp.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw-vpc1.id
    }
    tags = {
        Ambiente = "Medcloud-challenge"
        name = "rtb-webapp-public"
    }
}

resource "aws_route_table_association" "rta-subnet-1" {
    count = "${length(var.public-subnet_cidr)}"
    subnet_id = element(aws_subnet.public-subnet.*.id,count.index)
    route_table_id = aws_route_table.rtb-webapp-public.id
}

resource "aws_route_table" "rtb-webapp-private" {
    vpc_id = aws_vpc.vpc-webapp.id
    tags = {
        Ambiente = "Medcloud-challenge"
        name = "rtb-webapp-private"
    }
}

resource "aws_route_table_association" "rta-subnet-2" {
    count = "${length(var.public-subnet_cidr)}"
    subnet_id = element(aws_subnet.private-subnet.*.id,count.index)
    route_table_id = aws_route_table.rtb-webapp-private.id
}


# SECURITY GROUP
resource "aws_security_group" "sg-web" {
    name = "secgroup-web"
    description = "Allow Web Access traffic"
    vpc_id = aws_vpc.vpc-webapp.id
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}

resource "aws_security_group_rule" "web_port-80" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.sg-web.id
}

resource "aws_security_group_rule" "web_port-443" {
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.sg-web.id
}

resource "aws_security_group_rule" "web_egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.sg-web.id
}

resource "aws_security_group" "sg-db" {
    name = "secgroup-db"
    description = "Allow Database Access traffic"
    vpc_id = aws_vpc.vpc-webapp.id
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}

resource "aws_security_group_rule" "db_port-5432" {
    type = "ingress"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [var.vpc_cidr]
    security_group_id = aws_security_group.sg-db.id
}

resource "aws_security_group_rule" "db_egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.sg-db.id
}

resource "aws_security_group" "sg-ecs" {
    name = "secgroup-ecs"
    description = "Allow Container App Access traffic"
    vpc_id = aws_vpc.vpc-webapp.id
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}

resource "aws_security_group_rule" "ecs_port-8000" {
    type = "ingress"
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.sg-ecs.id
}

resource "aws_security_group_rule" "ecs_port-443" {
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.sg-ecs.id
}

resource "aws_security_group_rule" "ecs_egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.sg-ecs.id
}

resource "aws_security_group" "sg-bastion" {
    name = "secgroup-bastion"
    description = "Allow Bastion Access"
    vpc_id = aws_vpc.vpc-webapp.id
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}

resource "aws_security_group_rule" "ssh_port-22" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.myip}/32"]
    security_group_id = aws_security_group.sg-bastion.id
}

resource "aws_security_group_rule" "bastion_egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.sg-bastion.id
}


##############################################
# RDS
##############################################

resource "aws_db_subnet_group" "dbsubnetgroup" {
    name = "dbsubnetgroup"
    subnet_ids = [ aws_subnet.private-subnet[0].id,aws_subnet.private-subnet[1].id,aws_subnet.private-subnet[2].id,aws_subnet.private-subnet[3].id ]
}

resource "aws_db_instance" "dblojaonline" {
    identifier = var.db-identifier
    engine = var.db-engine
    engine_version = var.db-engine-version
    instance_class = var.db-instance-class
    
    db_name = var.db-name
    username = var.db-username
    password = var.db-password

    multi_az = false
    allocated_storage = 20  
    storage_type = "gp2"

    port = 5432
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.dbsubnetgroup.id
    vpc_security_group_ids = [ aws_security_group.sg-db.id ]
    skip_final_snapshot = true
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}

##############################################
# BASTION
##############################################

resource "aws_instance" "bastion" {
    depends_on = [aws_db_instance.dblojaonline]
    instance_type = "t3.micro"
    ami = "ami-0b0dcb5067f052a63"
    subnet_id = aws_subnet.public-subnet[0].id
    security_groups = [aws_security_group.sg-bastion.id]
    associate_public_ip_address = true
    key_name = "TESTE"
    connection {
        type        = "ssh"
        host        = self.public_ip
        user        = "ec2-user"
        private_key = file("./TESTE.pem")
    }
    provisioner "remote-exec" {
        inline = [
            "sudo yum update -y",
            "sudo amazon-linux-extras enable postgresql14",
            "sudo yum install postgresql -y",
            "echo 'create table produtos (id serial primary key, nome varchar, descricao varchar, preco decimal, quantidade integer);' > ./init-db.sql",
            "PGPASSWORD=${var.db-password}  psql -h ${aws_db_instance.dblojaonline.address} -U ${var.db-username} -d ${var.db-name} < ./init-db.sql"
        ]
    }
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}


##############################################
# ECR
##############################################

resource "aws_ecr_repository" "webapp-repository" {
    name = "webapp"
    image_tag_mutability = "MUTABLE"
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}

resource "aws_ecr_repository_policy" "webapp-repo-policy" {
  repository = aws_ecr_repository.webapp-repository.name
  policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "adds full ecr access to the webapp repository",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  EOF
}

##############################################
# ECS
##############################################

## AWS ROLE
resource "aws_iam_role" "webapp-task-execution-role" {
    name = var.iamrole-name
    assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
    statement {
      actions = ["sts:AssumeRole"]
      principals {
        type = "Service"
        identifiers = ["ecs-tasks.amazonaws.com"]
      }
    }
}

data "aws_iam_policy" "ecs_task_execution_role" {
    arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
    role = aws_iam_role.webapp-task-execution-role.name
    policy_arn = data.aws_iam_policy.ecs_task_execution_role.arn
}

#LOG STORAGE
resource "aws_cloudwatch_log_group" "Webapp" {
    name = "/ecs/webapp"
}

#Task Definition
resource "aws_ecs_task_definition" "webapp" {
    family = "webapp"
    execution_role_arn = aws_iam_role.webapp-task-execution-role.arn
    container_definitions = <<EOF
    [
        {
            "name": "webapp",
            "image": "${var.container_image}",
            "portMappings": [
                {
                    "containerPort": 8000,
                    "hostPort": 8000
                }
            ],
            "environment": [
                {
                    "name": "host",
                    "value": "${aws_db_instance.dblojaonline.address}"
                },
                {
                    "name": "dbname",
                    "value": "${var.db-name}"
                },
                {
                    "name": "user",
                    "value": "${var.db-username}"
                },
                {
                    "name": "password",
                    "value": "${var.db-password}"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-region": "us-east-1",
                    "awslogs-group": "/ecs/webapp",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
    EOF

    cpu = 512
    memory = 1024
    requires_compatibilities = [ "FARGATE" ]
    network_mode = "awsvpc"
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}


resource "aws_ecs_service" "ecs-webapp" {
    name = "ecs-webapp"
    task_definition = aws_ecs_task_definition.webapp.arn 
    cluster = aws_ecs_cluster.cluster-webapp.id
    launch_type = "FARGATE"
    desired_count = 1
    network_configuration {
        assign_public_ip = true
        security_groups = [aws_security_group.sg-ecs.id]
        subnets = [ aws_subnet.public-subnet[0].id, aws_subnet.public-subnet[1].id ]
    }
    load_balancer {
        target_group_arn = aws_lb_target_group.webapp.arn
        container_name = "webapp"
        container_port = "8000"
    }
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}

resource "aws_ecs_cluster" "cluster-webapp" {
    name = "cluster-webapp"
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}

##############################################
# LOAD BALANCER
##############################################

resource "aws_lb_target_group" "webapp" {
    name = "webapp"
    port = 8000
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = aws_vpc.vpc-webapp.id
    
    health_check {
        enabled = true
        path = "/"
    }

    depends_on = [aws_alb.alb-webapp]
}

resource "aws_alb" "alb-webapp" {
    name = "alb-webapp"
    internal = false
    load_balancer_type = "application"
    
    subnets = [ aws_subnet.public-subnet[0].id, aws_subnet.public-subnet[1].id ]
    security_groups = [aws_security_group.sg-web.id]
    depends_on = [aws_internet_gateway.igw-vpc1]
    tags = {
        Ambiente = "Medcloud-challenge"
    }
}

resource "aws_alb_listener" "alb-http" {
    load_balancer_arn = aws_alb.alb-webapp.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        type = "redirect"
        redirect {
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}

resource "aws_alb_listener" "alb-https" {
    depends_on = [aws_acm_certificate_validation.certificate_validation]
    load_balancer_arn = aws_alb.alb-webapp.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = aws_acm_certificate.webapp-certificate.arn
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.webapp.arn
    }
}

#DNS Record

resource "aws_route53_zone" "marcosfreytag_site" {
    name = var.domain_name
}

resource "aws_route53_record" "webapp" {
    allow_overwrite = true
    name = var.appname
    type = "CNAME"
    records = [ aws_alb.alb-webapp.dns_name ]
    ttl = 60
    zone_id = aws_route53_zone.marcosfreytag_site.zone_id
}

# certificate
resource "aws_acm_certificate" "webapp-certificate" {
    domain_name =  var.app-domain_name
    validation_method = "DNS"
    tags = {
      Ambiente = "Medcloud-challenge"
    }
    lifecycle {
      create_before_destroy = true
    }
}

 resource "aws_route53_record" "certificate-dns_record" {
    depends_on = [aws_acm_certificate.webapp-certificate]
    for_each = {
        for dvo in aws_acm_certificate.webapp-certificate.domain_validation_options : dvo.domain_name => {
            name   = dvo.resource_record_name
            record = dvo.resource_record_value
            type   = dvo.resource_record_type
        }
    }

    allow_overwrite = true
    name = each.value.name
    records = [each.value.record]
    ttl = 60
    type = each.value.type
    zone_id = aws_route53_zone.marcosfreytag_site.zone_id
}

resource "aws_acm_certificate_validation" "certificate_validation" {
    timeouts {
        create = "5m"
    }
    certificate_arn         = aws_acm_certificate.webapp-certificate.arn
    validation_record_fqdns = [for record in aws_route53_record.certificate-dns_record : record.fqdn]
}

##################################
# Monitoring
##################################

resource "aws_cloudwatch_dashboard" "cloudwatch-dashboard" {
    dashboard_name = "Dashboard_WEBAPP"
    dashboard_body =  file("./dashboard.json")
}