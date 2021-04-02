output "url" {
  value = aws_lb.my-aws-alb.*.dns_name
}
