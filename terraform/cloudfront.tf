resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "oac-${var.root_domain}"
  description                       = "OAC for ${var.root_domain} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  depends_on = [aws_acm_certificate_validation.site]

  enabled             = true
  comment             = "CloudFront distribution for ${var.root_domain}"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # Both apex and www use this distribution
  aliases = [
    var.root_domain,             # chris-nelson.dev
    "www.${var.root_domain}",    # www.chris-nelson.dev
  ]

  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = "s3-${aws_s3_bucket.site.bucket}"

    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.bucket}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "CloudFront for ${var.root_domain}"
  }
}
