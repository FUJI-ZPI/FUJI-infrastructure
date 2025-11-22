resource "aws_iam_role" "beanstalk_ec2_role" {
  name = "fuji-beanstalk-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "beanstalk_web_tier" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_docker" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ecr_read" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "beanstalk_ssm" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "beanstalk_ec2_profile" {
  name = "fuji-beanstalk-ec2-profile"
  role = aws_iam_role.beanstalk_ec2_role.name
}

resource "aws_iam_role" "beanstalk_service_role" {
  name = "fuji-beanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
    ]
  })
}

# Zarządzanie zdrowiem środowiska i aktualizacjami
resource "aws_iam_role_policy_attachment" "beanstalk_service_health" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "beanstalk_service" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

# S3
resource "aws_iam_role_policy" "beanstalk_s3_access" {
  name = "fuji_s3_db_access"
  role = aws_iam_role.beanstalk_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadingBackup"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.fuji_sounds.arn}",
          "${aws_s3_bucket.fuji_sounds.arn}/*",
          "${aws_s3_bucket.fuji_db_backups.arn}",
          "${aws_s3_bucket.fuji_db_backups.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user" "app_s3_user" {
  name = "fuji-backend-bot"
}

resource "aws_iam_access_key" "app_s3_key" {
  user = aws_iam_user.app_s3_user.name
}

resource "aws_iam_user_policy" "app_s3_policy" {
  name = "fuji-sound-bucket-access"
  user = aws_iam_user.app_s3_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAppToReadAndWriteSounds"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.fuji_sounds.arn}",
          "${aws_s3_bucket.fuji_sounds.arn}/*"
        ]
      }
    ]
  })
}
