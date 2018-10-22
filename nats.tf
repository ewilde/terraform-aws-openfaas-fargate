module "nats" {
    source                        = "./service-internal"
    name                          = "nats"
    ecs_cluster_name              = "${aws_ecs_cluster.openfaas.name}"
    aws_region                    = "${var.aws_region}"
    desired_count                 = "1"
    security_groups               = ["${aws_security_group.nats.id}", "${aws_security_group.service.id}"]
    allowed_subnets               = ["${aws_subnet.internal.*.id}"]
    namespace                     = "${var.namespace}"
    namespace_id                  = "${aws_service_discovery_private_dns_namespace.openfaas.id}"
    task_image                    = "ewilde/nats-streaming"
    task_image_version            = "0.9.2-linux"
    task_role_arn                 = "${aws_iam_role.ecs_role.arn}"
    task_ports                    = "[{\"containerPort\":4222,\"hostPort\":4222}, {\"containerPort\":8222,\"hostPort\":8222}]"
    task_command                  = <<CMD
[
    "--store",
    "memory",
    "--cluster_id",
    "faas-cluster"
]
CMD
}

resource "aws_security_group" "nats" {
    name = "${var.namespace}.nats"
    description = "nats security group"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-nats", var.namespace)}"
    }
}

resource "aws_security_group_rule" "nats_ingress_gateway" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.nats.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 4222
    to_port                  = 4222
    protocol                 = "all"
}

resource "aws_security_group_rule" "nats_management_ingress_gateway" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.nats.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 8222
    to_port                  = 8222
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "nats_ingress_service" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.nats.id}"
    source_security_group_id = "${aws_security_group.service.id}"
    from_port                = 4222
    to_port                  = 4222
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "nats_ingress_bastion" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.nats.id}"
    source_security_group_id = "${aws_security_group.bastion.id}"
    from_port                = 4222
    to_port                  = 4222
    protocol                 = "tcp"
    count                    = "${var.debug}"
}
