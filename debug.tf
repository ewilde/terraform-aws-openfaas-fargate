module "bastion_ami" {
    source = "./ami"
    name   = "amazon_ecs"
}

resource "aws_instance" "bastion" {
    count                       = "${var.debug}"
    ami                         = "${module.bastion_ami.ami_id}"
    source_dest_check           = false
    instance_type               = "t2.micro"
    subnet_id                   = "${element("${aws_subnet.external.*.id}", 0)}"
    key_name                    = "${var.bastion_keypair_name}"
    vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
    monitoring                  = true
    associate_public_ip_address = true
    tags {
        Name        = "${var.namespace}-bastion"
    }

    depends_on = ["aws_key_pair.bastion_ssh", "aws_internet_gateway.default"]
}

resource "aws_instance" "service" {
    count                       = "${var.debug}"
    ami                         = "${module.bastion_ami.ami_id}"
    source_dest_check           = false
    instance_type               = "t2.micro"
    subnet_id                   = "${element("${aws_subnet.internal.*.id}", 0)}"
    key_name                    = "${var.bastion_keypair_name}"
    vpc_security_group_ids      = ["${aws_security_group.service.id}"]
    monitoring                  = true
    associate_public_ip_address = false
    tags {
        Name        = "${var.namespace}-service"
    }

    depends_on = ["aws_key_pair.bastion_ssh", "aws_nat_gateway.default"]
}

resource "aws_security_group" "bastion" {
    count       = "${var.debug}"
    name        = "${var.namespace}.bastion"
    description = "Allow inbound ssh traffic"
    vpc_id      = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-bastion", var.namespace)}"
    }
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {
    count                    = "${var.debug}"
    type                     = "ingress"
    security_group_id        = "${aws_security_group.bastion.id}"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    cidr_blocks              = ["${var.developer_ip}/32"]
}

resource "aws_security_group_rule" "bastion_egress_ssh" {
    count                    = "${var.debug}"
    type                     = "egress"
    security_group_id        = "${aws_security_group.bastion.id}"
    source_security_group_id = "${aws_security_group.service.id}"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "bastion_egress_http" {
    count                    = "${var.debug}"
    type                     = "egress"
    security_group_id        = "${aws_security_group.bastion.id}"
    cidr_blocks              = ["0.0.0.0/0"]
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "bastion_egress_https" {
    count                    = "${var.debug}"
    type                     = "egress"
    security_group_id        = "${aws_security_group.bastion.id}"
    cidr_blocks              = ["0.0.0.0/0"]
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "bastion_egress_nats" {
    count                    = "${var.debug}"
    type                     = "egress"
    security_group_id        = "${aws_security_group.bastion.id}"
    source_security_group_id = "${aws_security_group.nats.id}"
    from_port                = 4222
    to_port                  = 4222
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "bastion_egress_gateway" {
    count                    = "${var.debug}"
    type                     = "egress"
    security_group_id        = "${aws_security_group.bastion.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "bastion_egress_services" {
    count                    = "${var.debug}"
    type                     = "egress"
    security_group_id        = "${aws_security_group.bastion.id}"
    source_security_group_id = "${aws_security_group.service.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "bastion_egress_ecs_provider" {
    count                    = "${var.debug}"
    type                     = "egress"
    security_group_id        = "${aws_security_group.bastion.id}"
    source_security_group_id = "${aws_security_group.ecs_provider.id}"
    from_port                = 8081
    to_port                  = 8081
    protocol                 = "tcp"
}

resource "aws_key_pair" "bastion_ssh" {
    key_name = "${var.bastion_keypair_name}"
    public_key = "${file("${path.module}/keys/${var.bastion_keypair_name}.pub")}"
}
