# infer-lambda-api

An example image recognition API using [infer](https://github.com/sjkaliski/infer) and AWS [Lambda](#) + [API Gateway](#).

## Overview

This project serves as an example for how to quickly deploy a Go Image Recognition API using Terraform and AWS. It uses [infer](https://github.com/sjkaliski/infer), a Go package that provides abstractions for interacting with TensorFlow models.

## Setup

### Build

Lambda functions require a zipped application containing the executable and any supporting assets. A `Dockerfile` has been provided to make the build step easy.

```
$ make build
```

Once executed, a `deployment.zip` file will be included in the root of the project. The zip includes:

- Lambda Function as a Go binary
- TensorFlow bindings
- Model file
- Labels file

### Deploy

Once the application has been built, it's ready to be deployed. The application is deployed as a Lambda function and uses API Gateway to provide HTTP access. [Terraform](https://www.terraform.io/) config has been included to make setup easy.

For an in-depth tutorial for using Terraform and Lambda/API Gateway, see [here](https://www.terraform.io/docs/providers/aws/guides/serverless-with-aws-lambda-and-api-gateway.html).

First, make sure you have a valid AWS account and have installed Terraform.

- [AWS Account](https://aws.amazon.com/)
- [Terraform](https://www.terraform.io/)

From there, initialize the Terraform build and apply. *Note: This will incur fees*.

```
$ cd terraform
$ terraform init
$ terraform apply
```

This creates the following

- S3 Bucket and Object containing deployment zip
- Lambda Function
- IAM Role
- API Gateway Rest API
- API Gateway Methods + Integrations into Lambda

Together, this results in a Lambda function that is accessible via HTTP over API Gateway.

### Teardown

```
$ terraform destroy
```

A version number will be required. Any semver value works.

## Usage

Locate the API Gateway Endpoint.

```
$ cd terraform
$ terraform output endpoint
```

Execute a request, example using `curl` below.

```
$ curl --upload-file "/path/to/img.png" "ENDPOINT" -H "Content-Type: image/png"
[
    {
        "Class": "thing",
        "Score": 0.875
    },
    ...
]
```

## Notes

- Lambda Function memory size set to 512mb. Any lower and the TF model could not execute.
- Startup time on first request can often be slow.
