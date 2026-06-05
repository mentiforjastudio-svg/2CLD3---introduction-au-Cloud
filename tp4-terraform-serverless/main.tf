# ============================================================
# TP 4 – 2CLD3 : Application serverless avec Terraform + LocalStack
# S3 (frontend) + API Gateway + Lambda Python + DynamoDB
# ============================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3         = "http://localhost:4566"
    dynamodb   = "http://localhost:4566"
    lambda     = "http://localhost:4566"
    apigateway = "http://localhost:4566"
    iam        = "http://localhost:4566"
  }
}

# ============================================================
# DYNAMODB — table des utilisateurs
# ============================================================

resource "aws_dynamodb_table" "users" {
  name         = "users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"

  attribute {
    name = "email"
    type = "S"
  }
}

# ============================================================
# IAM — rôle d'exécution pour Lambda
# ============================================================

resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda-dynamodb-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem"]
      Resource = aws_dynamodb_table.users.arn
    }]
  })
}

# ============================================================
# LAMBDA — packaging et déploiement des fonctions
# ============================================================

# Créer les archives ZIP à partir des fichiers Python
data "archive_file" "register_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/register.py"
  output_path = "${path.module}/lambda/register.zip"
}

data "archive_file" "login_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/login.py"
  output_path = "${path.module}/lambda/login.zip"
}

# Fonction inscription
resource "aws_lambda_function" "register" {
  filename         = data.archive_file.register_zip.output_path
  function_name    = "register"
  role             = aws_iam_role.lambda_role.arn
  handler          = "register.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.register_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users.name
    }
  }
}

# Fonction connexion
resource "aws_lambda_function" "login" {
  filename         = data.archive_file.login_zip.output_path
  function_name    = "login"
  role             = aws_iam_role.lambda_role.arn
  handler          = "login.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.login_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users.name
    }
  }
}

# ============================================================
# API GATEWAY — routes HTTP vers Lambda
# ============================================================

resource "aws_api_gateway_rest_api" "api" {
  name = "auth-api"
}

# --- Route /register ---

resource "aws_api_gateway_resource" "register" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "register"
}

resource "aws_api_gateway_method" "register_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.register.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "register" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.register.id
  http_method             = aws_api_gateway_method.register_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register.invoke_arn
}

# --- Route /login ---

resource "aws_api_gateway_resource" "login" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "login"
}

resource "aws_api_gateway_method" "login_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.login.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "login" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.login.id
  http_method             = aws_api_gateway_method.login_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.login.invoke_arn
}

# --- Déploiement de l'API ---

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  # Forcer un nouveau déploiement si les intégrations changent
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.register,
      aws_api_gateway_integration.login,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.register,
    aws_api_gateway_integration.login,
  ]
}

resource "aws_api_gateway_stage" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name    = "dev"
}

# --- Permissions : autoriser API Gateway à invoquer les Lambda ---

resource "aws_lambda_permission" "register" {
  statement_id  = "AllowAPIGatewayRegister"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "login" {
  statement_id  = "AllowAPIGatewayLogin"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# ============================================================
# S3 — frontend statique avec URL de l'API injectée
# ============================================================

locals {
  api_url = "https://${aws_api_gateway_rest_api.api.id}.execute-api.localhost.localstack.cloud:4566/${aws_api_gateway_stage.api.stage_name}"
}

resource "aws_s3_bucket" "frontend" {
  bucket = "auth-frontend"
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  content      = templatefile("${path.module}/frontend/index.html.tpl", { api_url = local.api_url })
  content_type = "text/html"
  etag         = md5(templatefile("${path.module}/frontend/index.html.tpl", { api_url = local.api_url }))
}

# ============================================================
# OUTPUTS — informations à noter après le déploiement
# ============================================================

output "frontend_url" {
  description = "URL du site frontend"
  value       = "https://localhost.localstack.cloud:4566/auth-frontend/index.html"
}

output "api_url" {
  description = "URL de base de l'API"
  value       = local.api_url
}

output "api_register_endpoint" {
  description = "Endpoint d'inscription"
  value       = "${local.api_url}/register"
}

output "api_login_endpoint" {
  description = "Endpoint de connexion"
  value       = "${local.api_url}/login"
}
