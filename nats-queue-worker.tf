module "nats_queue_worker" {
    source                        = "./service-internal"
    name                          = "nats-queue-worker"
    ecs_cluster_name              = "${aws_ecs_cluster.openfaas.name}"
    aws_region                    = "${var.aws_region}"
    desired_count                 = "1"
    security_groups               = ["${aws_security_group.service.id}", "${aws_security_group.nats_queue_worker.id}"]
    allowed_subnets               = ["${aws_subnet.internal.*.id}"]
    namespace                     = "${var.namespace}"
    namespace_id                  = "${aws_service_discovery_private_dns_namespace.openfaas.id}"
    task_image                    = "ewilde/queue-worker"
    task_image_version            = "latest" #"0.5.4"
    task_role_arn                 = "${aws_iam_role.ecs_provider_role.arn}"
    task_ports                    = "[]"
    task_env_vars                 = <<EOF
[
      {
        "name": "faas_nats_address",
        "value": "${module.nats.service_discovery_name}.${aws_service_discovery_private_dns_namespace.openfaas.name}"
      },
      {
        "name": "faas_gateway_address",
        "value": "${aws_service_discovery_service.gateway.name}.${aws_service_discovery_private_dns_namespace.openfaas.name}"
      },
      {
        "name": "faas_function_suffix",
        "value": ".${aws_service_discovery_private_dns_namespace.openfaas.name}"
      },
      {
        "name": "max_inflight",
        "value": "1"
      },
      {
        "name": "ack_wait",
        "value": "300s"
      },
      {
        "name": "basic_auth",
        "value": "false"
      }
    ]
EOF
}

resource "aws_security_group" "nats_queue_worker" {
    name = "${var.namespace}.nats-queue-worker"
    description = "Security rules for the nats queue worker"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-nats-queue-worker", var.namespace)}"
    }
}

resource "aws_security_group_rule" "nats_queue_worker_ingress_nats" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.nats_queue_worker.id}"
    source_security_group_id = "${aws_security_group.nats.id}"
    from_port                = 4222
    to_port                  = 4222
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "nats_queue_worker_egress_gateway" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.nats_queue_worker.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}
