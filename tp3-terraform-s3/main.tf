# ============================================================
# TP 3 – 2CLD3 : Déployer un site S3 avec Terraform + LocalStack
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 5.0"
    }
  }
}

provider "aws" {
  # Credentials fictives — LocalStack ne les vérifie pas
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  # Désactiver les vérifications AWS qui ne s'appliquent pas à LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Forcer le style path pour S3 : localhost:4566/bucket
  s3_use_path_style = true

  # Pointer tous les appels S3 vers LocalStack
  endpoints {
    s3 = "http://localhost:4566"
  }
}

# --- Ressource 1 : le bucket S3 ---
resource "aws_s3_bucket" "site" {
  bucket = "mon-site-tf-demo"
}

# --- Ressource 2 : la page d'accueil ---
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/index.html")
}

# --- Ressource 3 : la page d'erreur ---
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.site.id
  key          = "error.html"
  source       = "${path.module}/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/error.html")
}
