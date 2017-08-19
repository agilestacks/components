output "role_arn" {
  value = "${aws_iam_role.agilestacks.arn}"
}

output "account_id" {
  value = "${data.aws_caller_identity.customer.account_id}"
}