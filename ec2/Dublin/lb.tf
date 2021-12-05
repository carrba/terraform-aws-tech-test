resource "aws_lb" "ec2_lb" {
  name               = "nginx-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-security-group.id]
  subnets            = flatten([aws_subnet.public-subnets.*.id])
 

  enable_deletion_protection = false

  tags = {
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_security_group" "lb-security-group" {
  vpc_id = aws_vpc.vpc.id

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
  tags = {
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_lb_target_group" "vm" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  tags = {
    Owner   = var.owner
    Project = var.project
  }
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  count            = var.az_number
  target_group_arn = aws_lb_target_group.vm.arn
  target_id        = aws_instance.web-instance[count.index].id
  port             = 80
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.ec2_lb.arn
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vm.arn
  }

  tags = {
    Owner   = var.owner
    Project = var.project
  }
}

output "web_domain" {
  value = aws_lb.ec2_lb.dns_name
}