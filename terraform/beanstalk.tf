resource "aws_s3_bucket" "beanstalk_bucket" {
  bucket = "s3-zip-beanstalk-${random_id.bucket_id.hex}"
}

# Plik Dockerrun.aws.json na podstawie szablonu (.tftpl) wstrzyknięte do niego URL repozytorium ECR
data "template_file" "dockerrun" {
  template = file("${path.module}/Dockerrun.aws.json.tftpl")
  vars = {
    ecr_repository_url = aws_ecr_repository.fuji_ecr.repository_url
  }
}

data "archive_file" "app_zip" {
  type        = "zip"
  output_path = "${path.module}/fuji-app-bundle.zip" # Stworzy plik zip lokalnie

  source {
    content  = data.template_file.dockerrun.rendered
    filename = "Dockerrun.aws.json" # Nazwa pliku *wewnątrz* zipa
  }
}

resource "aws_s3_object" "app_bundle" {
  bucket = aws_s3_bucket.beanstalk_bucket.id
  key    = "fuji-app-bundle.zip"
  source = data.archive_file.app_zip.output_path
  etag   = data.archive_file.app_zip.output_md5
}

resource "aws_elastic_beanstalk_application" "fuji" {
  name        = "fuji"
  description = "Fuji backend on Docker (AL2023)"
}

resource "aws_elastic_beanstalk_application_version" "fuji_version" {
  name        = "v-${timestamp()}"
  application = aws_elastic_beanstalk_application.fuji.name
  bucket      = aws_s3_bucket.beanstalk_bucket.id
  key         = aws_s3_object.app_bundle.key

  lifecycle { create_before_destroy = true }
}

data "aws_region" "current" {}

data "aws_elastic_beanstalk_solution_stack" "latest_ecs" {
  most_recent = true
  
  name_regex  = "^64bit Amazon Linux 2023.*running ECS$"        # Docker dla v1
}

resource "aws_elastic_beanstalk_environment" "fuji_env" {
  name                = "fuji-backend-server"
  application         = aws_elastic_beanstalk_application.fuji.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.latest_ecs.name

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.private_subnet_a.id}, ${aws_subnet.private_subnet_b.id}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public_subnet_a.id}, ${aws_subnet.public_subnet_b.id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_service_role.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:backend"
    name      = "Port"
    value     = "80"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:backend"
    name      = "Protocol"
    value     = "HTTP"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:backend"
    name      = "HealthCheckPath"
    value     = "/actuator/health"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SPRING_PROFILES_ACTIVE"
    value     = "prod" # Aktywuje @Profile("prod") w Javie
  }
  # gdyby było za mało pamięci:
/*
    setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.small" # Zamiast domyślnego t3.micro. t3.small ma 2 GiB RAM.
  }
*/

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = "true"
  }

    setting {
    namespace = "aws:elbv2:listener:80"
    name      = "ListenerEnabled"
    value     = "false"
  }

  # Listener HTTPS (port 443)
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = aws_acm_certificate.api_cert.arn
  }
  depends_on = [aws_acm_certificate_validation.api_cert_validation]

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "DefaultProcess"
    value     = "backend" 
  }
  
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLPolicy"
    value     = "ELBSecurityPolicy-2016-08"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = aws_security_group.alb_sg.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.instance_sg.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVICE_DB_URL"
    value     = "jdbc:postgresql://${aws_db_instance.fuji.address}:5432/${aws_db_instance.fuji.db_name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVICE_DB_LOGIN"
    value     = var.SERVICE_DB_LOGIN
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVICE_DB_PASSWORD"
    value     = var.SERVICE_DB_PASSWORD
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVICE_DB_NAME"
    value     = var.SERVICE_DB_NAME
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "JWT_SECRET"
    value     = var.JWT_SECRET
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "GOOGLE_CLIENT_ID"
    value     = var.GOOGLE_CLIENT_ID
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OPENAI_API_KEY"
    value     = var.OPENAI_API_KEY
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MINIO_URL"
    value     = "s3.amazonaws.com"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MINIO_REGION"
    value = data.aws_region.current.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MINIO_BUCKET_NAME"
    value = aws_s3_bucket.fuji_sounds.id
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MINIO_ACCESS_KEY"
    value     = aws_iam_access_key.app_s3_key.id
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MINIO_SECRET_KEY"
    value     = aws_iam_access_key.app_s3_key.secret
  }

  version_label = aws_elastic_beanstalk_application_version.fuji_version.name
}

resource "aws_security_group" "alb_sg" {
  name        = "fuji-alb-sg"
  description = "Allow HTTP/HTTPS from Internet"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fuji-alb-sg"
  }
}

resource "aws_security_group" "instance_sg" {
  name   = "beanstalk-instance-sg"
  vpc_id = aws_vpc.main_vpc.id


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow database"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
