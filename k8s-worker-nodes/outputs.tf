output "bootstrap_script" {
  value = "file://${local_file.bootstrap_script.filename}"
}

output "bootstrap_script_s3" {
  value = "s3://${aws_s3_bucket_object.bootstrap_script.bucket}/${aws_s3_bucket_object.bootstrap_script.key}"
}
