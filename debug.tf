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

resource "aws_security_group" "bastion" {
    count       = "${var.debug}"
    name        = "${var.namespace}.bastion"
    description = "Allow inbound ssh traffic"
    vpc_id      = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-bastion", var.namespace)}"
    }
}

resource "aws_security_group_rule" "bastion-ingress-ssh" {
    count                    = "${var.debug}"
    type                     = "ingress"
    security_group_id        = "${aws_security_group.bastion.id}"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    cidr_blocks              = ["${var.developer_ip}/32"]
}

resource "aws_key_pair" "bastion_ssh" {
    key_name = "${var.bastion_keypair_name}"
    public_key = "${file("${path.module}/keys/${var.bastion_keypair_name}.pub")}"
}
