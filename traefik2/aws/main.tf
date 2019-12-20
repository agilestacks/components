terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.43.0"
}

provider "kubernetes" {
  version        = "1.9.0"
  config_context = "${var.kubeconfig_context}"
}

provider "null" {
  version = "2.1.2"
}

data "aws_region" "current" {}

data "aws_route53_zone" "ext_zone" {
  name = "${var.domain_name}"
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = "${var.component}"
    namespace = "${var.namespace}"
  }
}

resource "aws_route53_record" "dns_app1_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]
}

resource "aws_route53_record" "dns_app2_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "*.${var.url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]
}

resource "aws_route53_record" "dns_apps1_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.sso_url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]
}

resource "aws_route53_record" "dns_apps2_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "*.${var.sso_url_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"]
}

resource "null_resource" "drop_elb" {
  provisioner "local-exec" {
    when       = "destroy"
    on_failure = "continue"

    command = <<EOF
export AWS_DEFAULT_REGION="${data.aws_region.current.name}"
ELB_NAME="${element(split("-", element(split(".", "${data.kubernetes_service.traefik.load_balancer_ingress.0.hostname}"), 0)), 0)}"
SG_IDS=$(aws \
  elb describe-load-balancers \
  --load-balancer-names $ELB_NAME --query 'LoadBalancerDescriptions[*].SecurityGroups[*]' --output=text \
  | xargs)

echo "Delete ELB $ELB_NAME"
aws \
  elb delete-load-balancer  \
  --load-balancer-name=$ELB_NAME

for ID in "$SG_IDS"; do
  echo "Proceed with SG cleanup: $ID"
  SG_REVOKES=$(aws \
      ec2 describe-security-groups \
      --query "SecurityGroups[?contains(IpPermissions[].UserIdGroupPairs[].GroupId,'$ID')].GroupId" \
      --output=text | xargs )
  echo "Revoking ingress from: $SG_REVOKES"
  for R in $SG_REVOKES; do
    echo "Proceed revoke $R ingress route source: $ID"
    aws \
      ec2 revoke-security-group-ingress \
      --group-id "$R" --source-group "$ID" --protocol all;
  done;

  echo "Delete SG $ID"
  for n in $(seq 18); do
    aws \
      ec2 delete-security-group \
      --group-id="$ID" \
    && break;
    echo "Retry $n in 10sec..."
    sleep 10
  done
done
EOF
  }
}
