// Terraform does not have great support for Single Sign On yet.
// Right now when running locally, will need to go to SSO and copy/paste
// the session into the ~/.aws/credentials file, naming it "default" for now
// It is also assuming the role for the "playgound" account. This should
// be configured based on environment
//// provider "aws" {
////   profile = "default"
////   region  = "us-east-1"
////   assume_role {
////     role_arn     = "arn:aws:iam::054704909064:role/OrganizationAccountAccessRole"
////     session_name = "playground-organizationaccountaccessrole"
////   }
//// }

// We will provision this in the account with the Hosted Zone and ACM for now.
//
// 1. create s3
// 2. retrieve acm record
// 3. cloudfront distribution
// 4. A record in Route 53
// 5. Upload the index.html  

// TODO: Will need to update this to support multiple environments

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_s3_bucket" "resume_bucket" {
  bucket = "playground-billwong-resume"
  acl    = "public-read"
  policy = file("public_bucket_policy.json")

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  versioning {
    enabled = true
  }

  tags = {
    Application = "Resume"
    Environment = "Playground"
  }
}

// Find a certificate that is issued
data "aws_acm_certificate" "star-billwong-ca-certificate" {
  domain   = "*.billwong.ca"
  types    = ["AMAZON_ISSUED"]
  statuses = ["ISSUED"]
}

// CloudFront Distribution with S3 as source
locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "resume_website" {
  origin {
    domain_name = aws_s3_bucket.resume_bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "some comment"
  default_root_object = "index.html"

  aliases = ["playground.billwong.ca"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Application = "Resume"
    Environment = "Playground"
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.star-billwong-ca-certificate.arn
    ssl_support_method  = "sni-only"
  }

}

data "aws_route53_zone" "zone" {
  name         = "billwong.ca."
  private_zone = false
}

resource "aws_route53_record" "playground" {
  zone_id = data.aws_route53_zone.zone.id
  name    = "playground"
  type    = "A"

  alias {
    name                   = replace(aws_cloudfront_distribution.resume_website.domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.resume_website.hosted_zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_cloudfront_distribution.resume_website]
}

// Upload index.html to the s3 bucket
resource "null_resource" "deploy" {
  provisioner "local-exec" {
    command = "aws s3 cp ../public/index.html s3://playground-billwong-resume/"
  }
}