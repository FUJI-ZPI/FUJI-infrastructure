resource "aws_acm_certificate" "api_cert" {
  domain_name       = var.DOMAIN_NAME
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "fuji-site-cert"
  }
}

# To pozwoli wyciągnąć rekordy, które trzeba wpisać do Cloudflare
output "cert_validation_cname" {
  value = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
}

# ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
#                       Blokada czasowa
# Terraform zatrzyma się na tym zasobie i będzie czekał (nawet 45 min),
# aż zostaną dodane rekordy do Cloudflare i status certyfikatu zmieni się na Issued.
# ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
resource "aws_acm_certificate_validation" "api_cert_validation" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_acm_certificate.api_cert.domain_validation_options : record.resource_record_name]
}
