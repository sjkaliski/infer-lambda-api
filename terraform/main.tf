provider "aws" {
  region = "${var.region}"
}

# S3 Bucket and Object. This is where the application is located.
resource "aws_s3_bucket" "lambda" {
  bucket = "infer-lambda"
  acl    = "private"

  force_destroy = true
}

resource "aws_s3_bucket_object" "lambda" {
  bucket = "${aws_s3_bucket.lambda.id}"
  key    = "${var.version}/deployment.zip"
  source = "../deployment.zip"
  etag   = "${md5(file("../deployment.zip"))}"
}

# New function, uses s3 obj as source of function.
resource "aws_lambda_function" "main" {
  function_name = "InferLambdaExample"

  s3_bucket = "${aws_s3_bucket_object.lambda.bucket}"
  s3_key    = "${aws_s3_bucket_object.lambda.key}"

  handler = "build/main"
  runtime = "go1.x"

  role = "${aws_iam_role.lambda.arn}"

  memory_size = 512

  environment {
    variables = {
      LIBRARY_PATH    = "$LIBRARY_PATH:/var/task/build/lib"
      LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:/var/task/build/lib"
      MODEL           = "/var/task/build/graph.pb"
      LABELS          = "/var/task/build/labels.txt"
    }
  }
}

# IAM role to be used across resources.
resource "aws_iam_role" "lambda" {
  name               = "infer_lambda_example"
  assume_role_policy = "${data.aws_iam_policy_document.lambda.json}"
}

data "aws_iam_policy_document" "lambda" {
  statement = {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

# Create a REST API.
resource "aws_api_gateway_rest_api" "main" {
  name = "InferLambdaExample"

  binary_media_types = [
    "image/png",
    "image/jpeg",
  ]
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  parent_id   = "${aws_api_gateway_rest_api.main.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.main.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.main.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.main.id}"
  resource_id   = "${aws_api_gateway_rest_api.main.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.main.invoke_arn}"
}

resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.main.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.main.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_deployment.example.execution_arn}/*/*"
}
