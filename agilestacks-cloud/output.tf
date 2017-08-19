output "role_arn" {
  value = "${aws_iam_role.agilestacks.arn}"
}

output "account_id" {
  value = "${data.aws_caller_identity.client.account_id}"
}

output "base_hosted_zone_id" {
  value = "${data.aws_route53_zone.base.zone_id}"
}

output "hosted_zone_id" {
  value = "${aws_route53_zone.new.zone_id}"
}

output "s3_bucket" {
  value = "${aws_s3_bucket.main.bucket}"
}