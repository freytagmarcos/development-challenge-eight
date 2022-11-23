output "rds_name" {
    value = aws_db_instance.dblojaonline.address  
}

output "alb_url" {
    value = "http://${aws_alb.alb-webapp.dns_name}"  
}

output "ecr-repository" {
    value = aws_ecr_repository.webapp-repository.repository_url
}
