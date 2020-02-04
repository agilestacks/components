output "arn" {
  value = "${aws_lambda_function.main.arn}"
}


output "version" {
  value = "${aws_lambda_function.main.version}"
}

output "role_arn" {
  value = "${aws_iam_role.lambda_role.arn}"
}

output "name" {
  value = "${aws_lambda_function.main.function_name}"
}