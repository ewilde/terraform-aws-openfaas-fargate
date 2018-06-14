resource "aws_security_group" "alb" {
    name = "${var.namespace}.alb"
    description = "Allow OpenFaaS, Nomad and SSH Externally, everything on internal VPC"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-alb", var.namespace)}"
    }
}

resource "aws_security_group_rule" "alb-ingress" {
    type                     = "ingress"
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    cidr_blocks              = ["0.0.0.0/0"]
    security_group_id        = "${aws_security_group.alb.id}"
}

resource "aws_security_group" "gateway" {
    name = "${var.namespace}.gateway"
    description = "gateway security group. allows traffic from alb and to internal subnet"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-gateway", var.namespace)}"
    }
}

resource "aws_security_group_rule" "gateway-ingress-alb" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.alb.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway-egress-nats" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.service.id}"
    from_port                = 4222
    to_port                  = 4222
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway-egress-ecs-provider" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.service.id}"
    from_port                = 8081
    to_port                  = 8081
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway-egress-http" {
    type               = "egress"
    security_group_id  = "${aws_security_group.gateway.id}"
    from_port          = 80
    to_port            = 80
    protocol           = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "gateway-egress-https" {
    type               = "egress"
    security_group_id  = "${aws_security_group.gateway.id}"
    from_port          = 443
    to_port            = 443
    protocol           = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
}

resource "aws_security_group" "service" {
    name = "${var.namespace}.service"
    description = "service communication"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-service", var.namespace)}"
    }
}

resource "aws_security_group_rule" "service-ingress-ecs-provider" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.service.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 8081
    to_port                  = 8081
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "service-ingress-nats" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.service.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 4222
    to_port                  = 4222
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "service-ingress-bastion" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.service.id}"
    source_security_group_id = "${aws_security_group.bastion.id}"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "service-egress-http" {
    type               = "egress"
    security_group_id  = "${aws_security_group.service.id}"
    from_port          = 80
    to_port            = 80
    protocol           = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "service-egress-https" {
    type               = "egress"
    security_group_id  = "${aws_security_group.service.id}"
    from_port          = 443
    to_port            = 443
    protocol           = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
}
