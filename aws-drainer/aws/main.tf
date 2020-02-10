terraform {
  required_version = ">= 0.11.10"
  backend "s3" {}
}

provider "aws" {
  version = "2.14.0"
}

provider "kubernetes" {
  version        = "1.9.0"
  config_context = "${var.kubeconfig_context}"
}


data "aws_region" "current" {}


locals {
  r53_sync_dir = "${path.cwd}/lambda/asg-hook-sync"
}

data "local_file" "r53_sync_zip" {
  filename   = "${local.r53_sync_dir}/lambda.zip"
}

module "lambda_asg_sync" {
  source = "github.com/agilestacks/terraform-modules//lambda"
  name     = "asg-hook-sync-${replace(var.domain_name, ".", "-")}"
  handler  = "main.handler"
  zip_file = "${data.local_file.r53_sync_zip.filename}"
  policy   = "${file("${local.r53_sync_dir}/policy.json")}"
  tags     = {
      "kubernetes.io/cluster/${var.domain_name}" = "owned",
      "superhub.io/stack/${var.domain_name}"     = "owned",
  }
  env_vars  = {
    "DOMAIN_NAME" = "${var.domain_name}"
  }
}

resource "aws_cloudwatch_event_rule" "asg_monitor" {
  name        = "capture-asg-changes-${replace(var.domain_name, ".", "-")}"
  description = "Capture changes in ASG"
  event_pattern = <<PATTERN
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance Launch Successful",
    "EC2 Instance Terminate Successful",
    "EC2 Instance Launch Unsuccessful",
    "EC2 Instance Terminate Unsuccessful",
    "EC2 Instance-launch Lifecycle Action",
    "EC2 Instance-terminate Lifecycle Action"
  ]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "asg-target" {
  rule      = "${aws_cloudwatch_event_rule.asg_monitor.name}"
  arn       = "${module.lambda_asg_sync.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${module.lambda_asg_sync.name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.asg_monitor.arn}"
}

data "aws_lambda_invocation" "first_run" {
  function_name = "${module.lambda_asg_sync.name}"
  input = <<JSON
{
  "detail-type": "Dummy-event for initial run",
  "detail": { "AutoScalingGroupName": "DumyAutoScalingGroup" }
}
JSON
}