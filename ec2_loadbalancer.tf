#Create our app loadbalancer
resource "aws_lb" "loadbalancer" {
    internal            = "false"
    name                = "website-elb-${local.production_name}"
    subnets             = [aws_subnet.sub-a.id, aws_subnet.sub-b.id, aws_subnet.sub-c.id]
    security_groups     = [aws_security_group.loadbalancer.id]
}

#Create our groups for 80 then 443
resource "aws_lb_target_group" "lb_target_80" {
    name        = "website-80-${local.production_name}"
    port        = "80"
    protocol    = "HTTP"
    vpc_id      = aws_vpc.vpc.id
    target_type = "ip"

    #ECS task Running
    health_check {
        healthy_threshold   = "3"
        interval            = "10"
        port                = "80"
        path                = "/index.html"
        protocol            = "HTTP"
        unhealthy_threshold = "3"
    }
}

resource "aws_lb_listener" "lb_listener_80" {
    default_action {
        target_group_arn = aws_lb_target_group.lb_target_80.id
        type             = "forward"
    }

    load_balancer_arn = aws_lb.loadbalancer.arn
    port              = "80"
    protocol          = "HTTP"
}

resource "aws_lb_target_group" "lb_target_443" {
    name        = "website-443-${local.production_name}"
    port        = "443"
    protocol    = "HTTPS"
    vpc_id      = aws_vpc.vpc.id
    target_type = "ip"


    #ECS task Running
    health_check {
        healthy_threshold   = "3"
        interval            = "10"
        port                = "443"
        path                = "/index.html"
        protocol            = "HTTPS"
        unhealthy_threshold = "3"
    }
}

resource "aws_lb_listener" "lb_listener_443" {
    default_action {
        target_group_arn = aws_lb_target_group.lb_target_443.id
        type             = "forward"
    }
    #Replace with your ARN for your cert in ACM
    certificate_arn   = "arn:aws:acm:us-east-2:017300162920:certificate/c55387f1-d1ec-4d13-a270-73c347ef0f83"
    #Set Policy to a secure one
    ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
    load_balancer_arn = aws_lb.loadbalancer.arn
    port              = "443"
    protocol          = "HTTPS"
}

#Create our groups for 8080 for node
resource "aws_lb_target_group" "lb_target_8080" {
    name        = "node-8080-${local.production_name}"
    port        = "8080"
    protocol    = "HTTP"
    vpc_id      = aws_vpc.vpc.id
    target_type = "ip"

    #ECS task Running
    health_check {
        healthy_threshold   = "3"
        interval            = "10"
        port                = "8080"
        path                = "/"
        protocol            = "HTTP"
        unhealthy_threshold = "3"
    }
}

resource "aws_lb_listener" "lb_listener_8080" {
    default_action {
        target_group_arn = aws_lb_target_group.lb_target_8080.id
        type             = "forward"
    }

    load_balancer_arn = aws_lb.loadbalancer.arn
    port              = "8080"
    protocol          = "HTTP"
}

#Create our internal loadbalancer
resource "aws_lb" "internal_loadbalancer" {
    internal            = "true"
    name                = "lb-internal-${local.production_name}"
    load_balancer_type  = "network"
    subnet_mapping {
        subnet_id     = aws_subnet.sub-a.id
        private_ipv4_address = "10.0.0.101"
    }
    subnet_mapping {
        subnet_id     = aws_subnet.sub-b.id
        private_ipv4_address = "10.0.1.101"
  }
    subnet_mapping {
        subnet_id     = aws_subnet.sub-c.id
        private_ipv4_address = "10.0.2.101"
  }
}

resource "aws_lb_listener" "lb_listener_27017" {
    default_action {
        target_group_arn = aws_lb_target_group.lb_target_27017.id
        type             = "forward"
    }

    load_balancer_arn = aws_lb.internal_loadbalancer.arn
    port              = "27017"
    protocol          = "TCP"
}

resource "aws_lb_target_group" "lb_target_27017" {
    name        = "internal-27017-${local.production_name}"
    port        = "27017"
    protocol    = "TCP"
    vpc_id      = aws_vpc.vpc.id
    target_type = "ip"

    #ECS task Running
    health_check {
        healthy_threshold   = "3"
        interval            = "10"
        port                = "27017"
        protocol            = "TCP"
        unhealthy_threshold = "3"
    }
}

resource "aws_lb_listener" "lb_listener_5432" {
    default_action {
        target_group_arn = aws_lb_target_group.lb_target_5432.id
        type             = "forward"
    }

    load_balancer_arn = aws_lb.internal_loadbalancer.arn
    port              = "5432"
    protocol          = "TCP"
}

resource "aws_lb_target_group" "lb_target_5432" {
    name        = "internal-5432-${local.production_name}"
    port        = "5432"
    protocol    = "TCP"
    vpc_id      = aws_vpc.vpc.id
    target_type = "ip"

    #ECS task Running
    health_check {
        healthy_threshold   = "3"
        interval            = "10"
        port                = "5432"
        protocol            = "TCP"
        unhealthy_threshold = "3"
    }
}