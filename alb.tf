resource "aws_alb" "openfaas" {
    name            = "${var.namespace}-openfaas"
    internal        = false
    security_groups = ["${aws_security_group.allow_openfaas.id}"]
    subnets         = ["${aws_subnet.default.*.id}"]
}

resource "aws_alb_target_group" "openfaas" {
    name     = "${var.namespace}-openfaas"
    port     = 8080
    protocol = "HTTP"
    vpc_id   = "${aws_vpc.default.id}"

    health_check {
        path    = "/ui/"
        matcher = "200,202"
    }
}


