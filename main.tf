provider "aws" {
	region = "us-east-1"
}

resourse "aws_instance" "base" {
	ami = "ami-0742b4e673072066f"
	instance_type = "t2.micro"
	count = 2
	key_name = "${aws_key_pair.keypair.key_name}"
	vpc_security_group_ids = [aws_security_group.allow_ports.id]
	user_data = <<-EOF
					#!/bin/bash
					yum install httpd -y
					echo "hey i am $ (hostname -f)" > /var/www/html/index.html
					service httpd start
					chkconfig httpd on
			EOF
	tags={
	Name = "newEc2_arjun_614${count.index}"
	}
}

resource "aws_key_pair" "keypair" {
	key_name = "arjun614swen"
}

resource "aws_eip" "myeip" {
	count = length(aws_instance.base)
	vpc = true
	instance = "{$element(aws_instance.base.*.id,count.index)}"

	tags = {
	Name = "eip-arjun_614${count.index+1}"
	}
}

resource "aws_defualt_vpc" "default"{
	tags = {
	Name = "Default VPC"
	}
}

resource "aws_security_group" "ssh_http" {
  name        = "ssh_http"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnet_ids" "subnet" {
	vpc_id = "$aws_default_vpc.default.id"
}

resource "aws_lb_target_group" "my-target-group" {
	health_check {
		interval = 10
		path = "/"
		protocol = "HTTP"
		timeout = 5
		healthy_threshold = 5
	}

	name = "my-test-tg"
	port = 80
	protocol = "HTTP"
	target_type = "instance"
	vpc_id = "${aws_default_vpc.default.id}"
}

resource "aws_lb" "my-aws-alb" {
	name = "arjun-test-alb"
	internal = false
	security_group = [
	"${aws_security_group.allow_ports.id}",
	]

	subnets = data.aws_subnet_ids.subnet.ids
	tags = {
		Name = "arjun-test-alb"
	}
ip_address_type = "ipv4"
load_balancer_type = "application"
}

resource "aws_lb_listener" "arjun-test-alb-listener" {
	load_balancer_arn = aws_lb.my-aws-alb.arn
	port = 80
	protocol = "HTTP"
	default_action {
		target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
		type = "forward"
	}
}

resource "aws_alb_target_group_attachment" "ec2_attach" {
	count = length(aws_instance.base)
	target_group_arn = aws_lb_target_group.my-target-group.arn
	target_id = aws_instance.base[count.index].id
}
