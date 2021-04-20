# worth-lambda-example

A simple Python Lambda example, deployed with Terraform. 

## Getting Started 

- Ensure you have AWS CLI v2 and a recent version of Terraform installed 
- Ensure you have valid credentials for AWS and set `AWS_PROFILE` (or modify the Terraform Provider)
- Compress the Lambda for upload: `zip -r lambda_function.zip lambda_function/`
- Apply the Terraform to deploy: `terraform apply` 

The Lambda URL will be output, and you can then call the endpoint (as defined in `app.py`). 

eg. `curl https://{{id}}.execute-api.us-east-1.amazonaws.com/example/example_handler`