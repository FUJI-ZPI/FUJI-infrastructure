resource "aws_ecr_repository" "fuji_ecr" {
  name                 = "fuji"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_lifecycle_policy" "fuji_policy" {
  repository = aws_ecr_repository.fuji_ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Store only the last 3 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
