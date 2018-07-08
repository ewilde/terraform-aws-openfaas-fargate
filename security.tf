resource "aws_security_group" "alb" {
    name = "${var.namespace}.alb"
    description = "Allow OpenFaaS, Nomad and SSH Externally, everything on internal VPC"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-alb", var.namespace)}"
    }
}

resource "aws_security_group_rule" "alb_ingress" {
    type                     = "ingress"
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    cidr_blocks              = ["${var.developer_ip}/32"]
    security_group_id        = "${aws_security_group.alb.id}"
}

resource "aws_security_group_rule" "alb_egress" {
    type                     = "egress"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
    security_group_id        = "${aws_security_group.alb.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
}

resource "aws_security_group" "service" {
    name = "${var.namespace}.service"
    description = "common security group for all services in the internal subnet"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-service", var.namespace)}"
    }
}

resource "aws_security_group_rule" "service_ingress_bastion" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.service.id}"
    source_security_group_id = "${aws_security_group.bastion.id}"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    count                    = "${var.debug}"
}

resource "aws_security_group_rule" "service_ingress_functions_from_gateway" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.service.id}"
    source_security_group_id = "${aws_security_group.bastion.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
    count                    = "${var.debug}"
}

resource "aws_security_group_rule" "service_ingress_functions_service" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.service.id}"
    self                     = true
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "service_egress_functions_service" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.service.id}"
    self                     = true
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "service_egress_http" {
    type               = "egress"
    security_group_id  = "${aws_security_group.service.id}"
    from_port          = 80
    to_port            = 80
    protocol           = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "service_egress_https" {
    type               = "egress"
    security_group_id  = "${aws_security_group.service.id}"
    from_port          = 443
    to_port            = 443
    protocol           = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
}
