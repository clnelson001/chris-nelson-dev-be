data "archive_file" "status_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/status_handler.py"
  output_path = "${path.module}/../lambda/status_handler.zip"
}

resource "aws_iam_role" "status_lambda_role" {
  name = "chris-nelson-dev-status-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "status_lambda_policy" {
  name = "chris-nelson-dev-status-lambda-policy"
  role = aws_iam_role.status_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:DescribeAlarms"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "status" {
  function_name = "chris-nelson-dev-status"
  role          = aws_iam_role.status_lambda_role.arn
  handler       = "status_handler.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.status_lambda_zip.output_path

  environment {
    variables = {
      ALARM_NAME = aws_cloudwatch_metric_alarm.site_health_alarm.alarm_name
    }
  }
}

resource "aws_apigatewayv2_api" "status_api" {
  name          = "chris-nelson-dev-status-api"
  protocol_type = "HTTP"
  cors_configuration {
  allow_origins = ["https://chris-nelson.dev", "https://www.chris-nelson.dev"]
  allow_methods = ["GET", "OPTIONS"]
  allow_headers = ["*"]
}

}

resource "aws_apigatewayv2_integration" "status_integration" {
  api_id                 = aws_apigatewayv2_api.status_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.status.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "status_route" {
  api_id    = aws_apigatewayv2_api.status_api.id
  route_key = "GET /status"
  target    = "integrations/${aws_apigatewayv2_integration.status_integration.id}"
}

resource "aws_apigatewayv2_stage" "status_stage" {
  api_id      = aws_apigatewayv2_api.status_api.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_lambda_permission" "status_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.status.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.status_api.execution_arn}/*/*"
}

output "status_api_url" {
  description = "URL for uptime status API"
  value       = "${aws_apigatewayv2_api.status_api.api_endpoint}/${aws_apigatewayv2_stage.status_stage.name}/status"
}
################# NEW
data "archive_file" "status_api_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda/status_api_handler.py"
  output_path = "${path.module}/../lambda/status_api_handler.zip"
}

resource "aws_iam_role" "status_api_lambda" {
  name = "status-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "status_api_lambda_basic_logs" {
  role       = aws_iam_role.status_api_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "status_api" {
  function_name = "chris-nelson-status-api"

  role    = aws_iam_role.status_api_lambda.arn
  handler = "status_api_handler.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.status_api_lambda_zip.output_path
  source_code_hash = data.archive_file.status_api_lambda_zip.output_base64sha256

  timeout = 10
}
##### NEW
resource "aws_apigatewayv2_integration" "status_api_status_lambda" {
  api_id             = aws_apigatewayv2_api.status_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.status_api.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "status_latency_route" {
  api_id    = aws_apigatewayv2_api.status_api.id
  route_key = "GET /status/latency"
  target    = "integrations/${aws_apigatewayv2_integration.status_api_status_lambda.id}"
}

resource "aws_apigatewayv2_route" "status_health_route" {
  api_id    = aws_apigatewayv2_api.status_api.id
  route_key = "GET /status/health-checkers"
  target    = "integrations/${aws_apigatewayv2_integration.status_api_status_lambda.id}"
}

resource "aws_lambda_permission" "status_api_allow_invoke" {
  statement_id  = "AllowAPIGatewayInvokeStatusApiNew"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.status_api.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.status_api.execution_arn}/*/*"
}
