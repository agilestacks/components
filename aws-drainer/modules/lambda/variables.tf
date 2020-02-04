variable "name" {
  type = "string"
  description = "lambda function name"
}

variable "handler" {
  type = "string"
  description = "handler of lambda function"
  default = "main.handler"
}

variable "runtime" {
  type = "string"
  description = "describe your variable"
  default = "python3.7"
}

variable "timeout" {
  type = "string"
  description = "timeout in seconds"
  default = "60"
}

variable "ram" {
  type = "string"
  description = "container ram"
  default = "128"
}

variable "subnet_ids" {
  type = "list"
  description = "list of subnets for lambda to access vpc resources"
  default = []
}

variable "security_groups" {
  type = "list"
  description = "list of security groups for lambda to access vpc resources"
  default = []
}

variable "zip_file" {
  type = "string"
  description = "zip file with lambda function from s3"
}

variable "kms_key_arn" {
  type = "string"
  description = "ARN of the KMS key to store sensitive information for lambda"
  default = ""
}

variable "variables" {
  type = "map"
  description = "AWS Lambda environment variables"
  default = {
  }
}

variable "policy" {
  type = "string"
  description = "Execution policy for lambda"
  default =<<EOF
{
  "Version": "2012-10-17",
  "Statement": [ {
    "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:AttachNetworkInterface"
    ],
    "Effect": "Allow",
    "Resource": "*"
  },
  {
    "Action": [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ],
    "Resource": "*",
    "Effect": "Allow"
  }]
}
EOF
}

variable "tags" {
  description = "AWS tags to be applied to created resources."
  type        = "map"
  default     = {}
}

variable "env_vars" {
  description = "Enviroment variables"
  type        = "map"
  default     = {}
}