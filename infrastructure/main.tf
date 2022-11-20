##############################################
# NETWORK
##############################################

# VPC
resource "aws_vpc" "vpc-webapp" {
   cidr_block = var.vpc_cidr
   enable_dns_hostnames = true
   tags = {
     Name = "VPC-Webapp"
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
        name = "Subnet-public-${count.index+1}"
    }
}

resource "aws_subnet" "private-subnet" {
    count = "${length(var.private-subnet_cidr)}"
    cidr_block = element(var.private-subnet_cidr,count.index)
    availability_zone = element(var.availability_zone,count.index)
    vpc_id = aws_vpc.vpc-webapp.id
    tags = {
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
}

resource "aws_route_table_association" "rta-subnet-1" {
    count = "${length(var.public-subnet_cidr)}"
    subnet_id = element(aws_subnet.public-subnet.*.id,count.index)
    route_table_id = aws_route_table.rtb-webapp-public.id
}

resource "aws_route_table" "rtb-webapp-private" {
    vpc_id = aws_vpc.vpc-webapp.id
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
}

resource "aws_security_group_rule" "db_port-5432" {
    type = "ingress"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
}

resource "aws_security_group_rule" "ecs_port-8000" {
    type = "ingress"
    from_port = 8000
    to_port = 8000
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


##############################################
# RDS
##############################################

resource "aws_db_subnet_group" "dbsubnetgroup" {
    name = dbsubnetgroup
    subnet_ids = [ aws_subnet.private-subnet[0].id,aws_subnet.private-subnet[1].id,aws_subnet.private-subnet[2].id,aws_subnet.private-subnet[3].id ]
}

resource "aws_db_instance" "dblojaonline" {
    name = "dblojaonline"
    engine = "postgres"
    engine_version = "14.1"
    instance_class = "db.t3.small"
    
    db_name = "lojaonline"
    username = "postgres"
    password = "postgres"

    multi_az = false
    allocated_storage = 5  
    storage_type = "io1"

    port = 5432
    publicly_accessible = false
    db_subnet_group_name = aws_db_subnet_group.dbsubnetgroup.id
    vpc_security_group_ids = [ aws_security_group.sg-db.id ]
    
    provisioner "local-exec" {
      command = "psql --host=${self.address} --port=${self.port} --user=${self.username} --password=${self.password} < ./schema.sql"
    }
}

##############################################
# ECR
##############################################

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
            "image": "freytagmarcos/appweb:latest",
            "portMappings": [
                {
                    "containerPort": 8000
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-region": "us-east-1",
                    "awslogs-group": "/ecs/webapp",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
    EOF

    cpu = 256
    memory = 512
    requires_compatibilities = [ "FARGATE" ]
    network_mode = "awsvpc"
}


resource "aws_ecs_service" "ecs-webapp" {
    name = "ecs-webapp"
    task_definition = aws_ecs_task_definition.webapp.arn 
    cluster = aws_ecs_cluster.cluster-webapp.id
    launch_type = "FARGATE"
    desired_count = 1
    network_configuration {
        assign_public_ip = false
        security_groups = [aws_security_group.sg-ecs.id]
        subnets = [ aws_subnet.private-subnet[0].id, aws_subnet.private-subnet[1].id ]
    }
    load_balancer {
        target_group_arn = aws_lb_target_group.webapp.arn
        container_name = "webapp"
        container_port = "8000"
    }
}

resource "aws_ecs_cluster" "cluster-webapp" {
    name = "cluster-webapp"
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
}

output "alb_url" {
    value = "http://${aws_alb.alb-webapp.dns_name}"  
}
