resource "aws_lb" "openfaas" {
    name               = "${var.namespace}-openfaas"
    internal           = false
    security_groups    = ["${aws_security_group.alb.id}"]
    subnets            = ["${aws_subnet.external.*.id}"]
    load_balancer_type = "application"
}

resource "aws_lb_target_group" "openfaas" {
    name        = "${var.namespace}-openfaas"
    port        = 8080
    protocol    = "HTTP"
    vpc_id      = "${aws_vpc.default.id}"

    target_type = "ip"
    health_check {
        path    = "/ui/"
        matcher = "200,202"
    }
}

resource "aws_lb_listener" "openfaas" {
    load_balancer_arn = "${aws_lb.openfaas.arn}"
    port              = 80
    protocol          = "HTTP"
    default_action {
        target_group_arn = "${aws_lb_target_group.openfaas.arn}"
        type             = "forward"
    }
}

