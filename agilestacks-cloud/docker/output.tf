output "aws_account_number" {
  value = "${data.aws_caller_identity.client.account_id}"
}

output "parent_domain_zone_id" {
  value = "${data.aws_route53_zone.base.zone_id}"
}

output "base_domain_zone_id" {
  value = "${aws_route53_zone.new.zone_id}"
}

output "s3_bucket_name" {
  value = "${aws_s3_bucket.main.bucket}"
}

output "s3_bucket_region" {
  value = "${aws_s3_bucket.main.region}"
}

output "base_domain" {
  value = "${aws_route53_zone.new.name}"
}
