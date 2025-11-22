output "backend_url" {
  description = "Public URL of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.fuji_env.endpoint_url
}

output "ecr_repository_url" {
  description = "Public URL of the ECR (for GitHub Actions)"
  value       = aws_ecr_repository.fuji_ecr.repository_url
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.fuji.address
}

output "db_name" {
  description = "DB name"
  value = aws_db_instance.fuji.db_name
}

output "s3_sounds_bucket_url" {
  description = "Bucket used for sound files"
  value       = aws_s3_bucket.fuji_sounds.bucket_domain_name
}

output "s3_sounds_bucket_name" {
  description = "Bucket used for sound files"
  value       = aws_s3_bucket.fuji_sounds.bucket
}

output "acm_certificate_validation_records" {
  value = aws_acm_certificate.api_cert.domain_validation_options
}
