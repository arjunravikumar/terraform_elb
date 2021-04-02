output "url for the website" {
  value = aws_lb.my-aws-alb.*.dns_name
}
