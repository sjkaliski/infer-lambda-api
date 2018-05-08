output "endpoint" {
  value = "${aws_api_gateway_deployment.example.invoke_url}"
}

output "version" {
  value = "${var.version}"
}
