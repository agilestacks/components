locals {
  function_name = "${substr(var.name, 0, min(length(var.name), 64))}"
  function_role_name_prefix = "${substr(local.function_name, 0, min(length(local.function_name), 32))}"
}

resource "aws_lambda_function" "main" {
    function_name    = "${local.function_name}"
    filename         = "${data.local_file.archive.filename}"
    runtime          = "${var.runtime}"
    role             = "${aws_iam_role.lambda_role.arn}"
    handler          = "${var.handler}"
    memory_size      = "${var.ram}"
    timeout          = "${var.timeout}"
    publish          = true
    tags             = "${var.tags}"
    environment {
        variables = "${var.env_vars}"
    } 
}

data "local_file" "archive" {
    filename = "${var.zip_file}"
}

# resource "aws_lambda_alias" "latest" {
#     name = "${uuid()}"
#     description = "Alias that points to the lambda latest tag"
#     function_name = "${aws_lambda_function.main.arn}"
#     function_version = "$LATEST"
# }

resource "aws_iam_role" "lambda_role" {
    name_prefix = "${local.function_role_name_prefix}"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"}
    ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
    name = "${local.function_name}-lambda-execution"
    role = "${aws_iam_role.lambda_role.id}"
    policy="${var.policy}"
}
