output "url" {
  value = aws_instance.base.*.public_ip
}
