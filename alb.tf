# Create an Application Load Balancer (ALB)
resource "aws_lb" "nginx_lb" {
  name               = "nginx-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nginx_sg.id]
  subnets            = aws_subnet.public[*].id
}

# Create a Target Group for the Nginx containers
resource "aws_lb_target_group" "nginx_tg" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ecs_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200-299"
  }
}

# Create a Listener for the ALB
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.nginx_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.nginx_tg.arn
    type             = "forward"
  }
}
