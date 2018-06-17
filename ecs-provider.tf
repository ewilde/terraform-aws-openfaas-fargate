module "ecs_provider" {
    source                        = "./service-internal"
    name                          = "ecs-provider"
    ecs_cluster_name              = "${var.ecs_cluster_name}"
    aws_region                    = "${var.aws_region}"
    desired_count                 = "1"
    security_groups               = ["${aws_security_group.service.id}"]
    allowed_subnets               = ["${aws_subnet.internal.*.id}"]
    namespace                     = "${var.namespace}"
    service_discovery_service_arn = "${aws_service_discovery_service.ecs_provider.arn}"
    task_image                    = "ewilde/faas-ecs"
    task_image_version            = "latest"
    task_role_arn                 = "${aws_iam_role.ecs_role.arn}"
    task_ports                    = "[{\"containerPort\":8081,\"hostPort\":8081}]"
    task_env_vars                 = <<EOF
[
  {
     "name"  : "port",
     "value" : "8081"
  }
]
EOF
}

resource "aws_security_group_rule" "gateway-egress-ecs-provider" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.service.id}"
    from_port                = 8081
    to_port                  = 8081
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "service-ingress-ecs-provider" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.service.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 8081
    to_port                  = 8081
    protocol                 = "tcp"
}
