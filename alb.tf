resource "aws_lb" "application_lb" {
  provider           = aws.region_master
  name               = "jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  tags = {
    Name = "Jenkins_LB"
  }
}

resource "aws_lb_target_group" "app_lb_tg" {
  provider    = aws.region_master
  name        = "app-lb-tg"
  port        = var.webserver_port
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_master.id
  protocol    = "HTTP"

  health_check {
    enabled  = true
    interval = 10
    path     = "/"
    port     = var.webserver_port
    protocol = "HTTP"
    matcher  = "200-299"
  }

  tags = {
    Name = "jenkins_target_group"
  }
}

resource "aws_lb_listener" "jenkins_lsitener_http" {
  provider          = aws.region_master
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "jenkins_listener_https" {
  provider          = aws.region_master
  load_balancer_arn = aws_lb.application_lb.arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.jenkins_lb_https.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_lb_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "jenkins_master_attach" {
  provider         = aws.region_master
  target_group_arn = aws_lb_target_group.app_lb_tg.arn
  target_id        = aws_instance.jenkins_master.id
  port             = var.webserver_port
}