terraform {
  required_version = ">= 0.11.3"
  backend          "s3"             {}
}

provider "aws" {
  version = "1.41.0"
}

provider "kubernetes" {
  version        = "1.1.10"
  config_context = "${var.domain_name}"
}

data "aws_region" "current" {}

data "aws_route53_zone" "ext_zone" {
  name = "${var.domain_name}"
}

data "kubernetes_service" "harbor_nginx" {
  metadata {
    name      = "${var.nginx_service_name}"
    namespace = "${var.namespace}"
  }
}

resource "aws_route53_record" "dns_app_ext" {
  zone_id = "${data.aws_route53_zone.ext_zone.zone_id}"
  name    = "${var.component}.${var.service_prefix}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${data.kubernetes_service.harbor_nginx.load_balancer_ingress.0.hostname}"]

  lifecycle {
    ignore_changes = ["records", "ttl"]
  }
}

resource "null_resource" "drop_elb" {
  provisioner "local-exec" {
    when       = "destroy"
    on_failure = "continue"

    command = <<EOF
export AWS_DEFAULT_REGION="${data.aws_region.current.name}"
ELB_NAME="${element(split("-", element(split(".", "${data.kubernetes_service.harbor_nginx.load_balancer_ingress.0.hostname}"), 0)), 0)}"
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
  for R in "$SG_REVOKES"; do
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
