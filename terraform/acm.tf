# ---------------------------------------------------------------------------
# Lookup of the existing public hosted zone for the root domain
#
# The hosted zone is managed in the separate dns stack. This data source
# locates the existing public hosted zone by name so that ACM validation
# records can be created in that zone.
# ---------------------------------------------------------------------------
data "aws_route53_zone" "main" {
  name         = var.root_domain
  private_zone = false
}

# ---------------------------------------------------------------------------
# ACM certificate for the domain, issued in us-east-1
#
# CloudFront requires certificates to reside in the us-east-1 region, so the
# aws.us_east_1 provider alias is used. The certificate covers the apex domain
# and the www subdomain and uses DNS validation. The create_before_destroy
# lifecycle rule allows seamless certificate rotation.
# ---------------------------------------------------------------------------
resource "aws_acm_certificate" "site" {
  provider          = aws.us_east_1
  domain_name       = var.root_domain
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.root_domain}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Certificate for ${var.root_domain}"
  }
}

# ---------------------------------------------------------------------------
# DNS validation records required for ACM certificate issuance
#
# Each domain validation option returned by ACM includes a record name, type,
# and value. One Route53 record is created per validation entry. A short TTL
# ensures rapid propagation.
# ---------------------------------------------------------------------------
resource "aws_route53_record" "site_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# ---------------------------------------------------------------------------
# ACM certificate validation
#
# Confirms validation of the issued ACM certificate using the DNS records
# created above. CloudFront cannot use the certificate until this step
# completes successfully.
# ---------------------------------------------------------------------------
resource "aws_acm_certificate_validation" "site" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [
    for record in aws_route53_record.site_cert_validation : record.fqdn
  ]
}
