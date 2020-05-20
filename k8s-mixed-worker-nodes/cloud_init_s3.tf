locals {
    cloud_init_worker_upload_path      = "${var.s3_base_path}/cloud-init/cloud-init-k8s-worker-init.yaml"
}

resource "aws_s3_bucket_object" "cloud_init_k8s_worker" {
  provider     = aws.bucket
  bucket       = var.s3_bucket
  key          = local.cloud_init_worker_upload_path
  content      = data.template_file.cloud_init_k8s_worker.rendered
  acl          = "private"
  content_type = "text/plain"
  server_side_encryption = "AES256"
}
