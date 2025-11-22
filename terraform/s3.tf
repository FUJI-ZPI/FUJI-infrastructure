resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "fuji_sounds" {
  bucket = "fuji-app-sound${random_id.bucket_id.hex}"

  tags = {
    Name = "Fuji Sound Files"
  }
}

resource "aws_s3_bucket" "fuji_db_backups" {
  bucket = "fuji-db-backups-${random_id.bucket_id.hex}"

  tags = {
    Name = "Fuji Database Backups"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main_vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids = [aws_route_table.private_rt_a.id, aws_route_table.private_rt_b.id]
}
