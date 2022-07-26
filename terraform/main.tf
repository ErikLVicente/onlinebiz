provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "aws_s3_bucket" "site" {
  bucket = var.site_domain
}

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.site.id

  acl = "public-read"
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_bucket" "www" {
  bucket = "www.${var.site_domain}"
}

resource "aws_s3_bucket_acl" "www" {
  bucket = aws_s3_bucket.www.id

  acl = "private"
}

resource "aws_s3_bucket_website_configuration" "www" {
  bucket = aws_s3_bucket.www.id

  redirect_all_requests_to {
    host_name = var.site_domain
  }
}

terraform {
  backend "s3" {
    bucket = "onlinebiz.com.br"
    key    = "path/to/my/key"
    region = "us-west-2"
  }
}

# data "cloudflare_zones" "domain" {
#   filter {
#     name = var.site_domain
#   }
# }

# resource "cloudflare_record" "site_cname" {
#   zone_id = data.cloudflare_zones.domain.zones[0].id
#   name    = var.site_domain
#   value   = aws_s3_bucket_website_configuration.site.website_endpoint
#   type    = "CNAME"

#   ttl     = 1
#   proxied = true
# }

# resource "cloudflare_record" "www" {
#   zone_id = data.cloudflare_zones.domain.zones[0].id
#   name    = "www"
#   value   = var.site_domain
#   type    = "CNAME"
  
#   ttl     = 1
#   proxied = true
# }

# resource "aws_s3_object" "dist" {
#   for_each = fileset("/home/erikvicente/git/onlinebiz/website", "*")

#   bucket = aws_s3_bucket.www.id
#   key    = each.value
#   source = "/home/erikvicente/git/onlinebiz/website/${each.value}"
#   # etag makes the file update when it changes; see https://stackoverflow.com/questions/56107258/terraform-upload-file-to-s3-on-every-apply
#   etag   = filemd5("/home/erikvicente/git/onlinebiz/website/${each.value}")
# }

resource "aws_s3_bucket_object" "file_upload" {
  bucket = aws_s3_bucket.www.id
  key    = "/"
  source = "./website/index.html"
  etag   = "${filemd5("./website/index.html")}"
}
