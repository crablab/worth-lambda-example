# Configure Terraform Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

locals {
    name = "example"
}

// ==== LAMBDA ====
// IAM role for Lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "${local.name}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

// Lambda declaration
resource "aws_lambda_function" "lambda" {
  
  function_name = local.name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.app.example_handler"
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  runtime = "python3.8"
}
// API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "${local.name}_api"
}

// Resource (endpoint) that can be called
resource "aws_api_gateway_resource" "resource" {
  // Passes all requests through
  path_part   = "{proxy+}"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

// HTTP methods allowd (any)
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

// Links resources together 
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

// Deploys the integration
resource "aws_api_gateway_deployment" "deployment" {
   depends_on = [
     aws_api_gateway_integration.integration,
   ]

   rest_api_id = aws_api_gateway_rest_api.api.id
   stage_name  = local.name
}

// Gives API Gateway permissions to execute 
resource "aws_lambda_permission" "apigw_lambda" {  
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"

  depends_on = [
    aws_api_gateway_rest_api.api,
  ]
}

// ==== OUTPUTS ==== 
output "lambda_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}