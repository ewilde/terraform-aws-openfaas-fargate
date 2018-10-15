resource "aws_lb" "openfaas" {
    name               = "${var.namespace}"
    internal           = false
    security_groups    = ["${aws_security_group.alb.id}"]
    subnets            = ["${aws_subnet.external.*.id}"]
    load_balancer_type = "application"
}

resource "aws_lb_target_group" "gateway" {
    name        = "${var.namespace}-gateway"
    port        = 8080
    protocol    = "HTTP"
    vpc_id      = "${aws_vpc.default.id}"

    target_type = "ip"
    health_check {
        path    = "/ui/"
        matcher = "200,202"
    }
}

resource "aws_lb_listener" "gateway" {
    load_balancer_arn = "${aws_lb.openfaas.arn}"
    port              = 80
    protocol          = "HTTP"
    default_action {
        target_group_arn = "${aws_lb_target_group.gateway.arn}"
        type             = "forward"
    }
}

resource "aws_lb_target_group" "prometheus" {
    name        = "${var.namespace}-prometheus"
    port        = 9090
    protocol    = "HTTP"
    vpc_id      = "${aws_vpc.default.id}"

    target_type = "ip"
    health_check {
        path    = "/graph"
        matcher = "200"
    }
}

resource "aws_lb_listener" "prometheus" {
    load_balancer_arn = "${aws_lb.openfaas.arn}"
    port              = 9090
    protocol          = "HTTP"
    default_action {
        target_group_arn = "${aws_lb_target_group.prometheus.arn}"
        type             = "forward"
    }
}

resource "aws_security_group" "alb" {
    name = "${var.namespace}.alb"
    description = "Alb security group rules"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-alb", var.namespace)}"
    }
}

resource "aws_security_group_rule" "alb_ingress_gateway" {
    type                     = "ingress"
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    cidr_blocks              = ["${var.developer_ip}/32"]
    security_group_id        = "${aws_security_group.alb.id}"
}

resource "aws_security_group_rule" "alb_ingress_prometheus" {
    type                     = "ingress"
    from_port                = 9090
    to_port                  = 9090
    protocol                 = "tcp"
    cidr_blocks              = ["${var.developer_ip}/32"]
    security_group_id        = "${aws_security_group.alb.id}"
}

resource "aws_security_group_rule" "alb_egress_gateway" {
    type                     = "egress"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
    security_group_id        = "${aws_security_group.alb.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
}

resource "aws_security_group_rule" "alb_egress_prometheus" {
    type                     = "egress"
    from_port                = 9090
    to_port                  = 9090
    protocol                 = "tcp"
    security_group_id        = "${aws_security_group.alb.id}"
    source_security_group_id = "${aws_security_group.prometheus.id}"
}

