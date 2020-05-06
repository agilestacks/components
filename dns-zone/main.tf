terraform {
  backend "s3" {}
}

data "aws_route53_zone" "parent" {
  name = var.base_domain
}

resource "aws_route53_zone" "current" {
  name = "${var.name}.${var.base_domain}"
}

resource "aws_route53_record" "parent" {
  name            = "${var.name}.${var.base_domain}"
  ttl             = 60
  type            = "NS"
  zone_id         = data.aws_route53_zone.parent.zone_id

  records = [
    aws_route53_zone.current.name_servers.0,
    aws_route53_zone.current.name_servers.1,
    aws_route53_zone.current.name_servers.2,
    aws_route53_zone.current.name_servers.3
  ]
}
