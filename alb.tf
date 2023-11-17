resource "aws_lb" "lb" {
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.discovery.public_subnets
}

resource "aws_security_group" "lb_sg" {
    vpc_id = module.discovery.vpc_id
}

resource "aws_security_group_rule" "lb_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

resource "aws_security_group_rule" "lb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

resource "aws_lb_target_group" "target_group" {
  name     = "target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.discovery.vpc_id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}