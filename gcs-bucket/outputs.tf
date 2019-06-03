output "bucket" {
  value = "${google_storage_bucket.main.name}"
}

output "url" {
  value = "${google_storage_bucket.main.url}"
}
