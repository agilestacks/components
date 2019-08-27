resource "null_resource" "metal" {
  provisioner "local-exec" {
    command = "'echo nothing to do. this is metal, baby!'"
  }
}
