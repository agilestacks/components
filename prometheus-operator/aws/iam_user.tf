/*
resource "null_resource" "clenup_policies" {
  provisioner "local-exec" {
    when = "destroy"
    on_failure = "continue"

    command=<<EOF
#!/bin/bash
policies=$(aws --region=${data.aws_region.current.name} iam list-user-policies --user-name=${aws_iam_user.main.name} --query=PolicyNames[] --output=json | xargs)
for policy in "$policies"; do
  echo "Delete IAM policy: $policy"
  aws --region="${data.aws_region.current.name}" iam delete-user-policy --user-name="${aws_iam_user.main.name}" --policy-name="$policy"
done
EOF
  }
}

resource "aws_iam_user" "main" {
  name = "${var.username}-${var.domain}"
  path = "${var.path}"
  force_destroy = true
}

resource "aws_iam_access_key" "main" {
  user    = "${aws_iam_user.main.name}"
}

resource "aws_iam_user_policy" "root" {
  name_prefix  = "thanos-bucket"
  user = "${aws_iam_user.main.name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Statement",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.main.arn}/*",
                "${aws_s3_bucket.main.arn}"
            ]
        }
    ]
}
EOF
}
*/
