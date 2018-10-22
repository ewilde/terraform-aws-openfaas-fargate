module "prometheus" {
    source                        = "./service-internal-with-lb"
    name                          = "prometheus"
    ecs_cluster_name              = "${aws_ecs_cluster.openfaas.name}"
    aws_region                    = "${var.aws_region}"
    desired_count                 = "1"
    security_groups               = ["${aws_security_group.service.id}", "${aws_security_group.prometheus.id}"]
    allowed_subnets               = ["${aws_subnet.internal.*.id}"]
    namespace                     = "${var.namespace}"
    namespace_id                  = "${aws_service_discovery_private_dns_namespace.openfaas.id}"
    task_image                    = "ewilde/prometheus"
    task_image_version            = "v2.3.1"
    task_role_arn                 = "${aws_iam_role.prometheus_role.arn}"
    task_ports                    = "[{\"containerPort\":9090,\"hostPort\":9090}]"
    task_env_vars                 = <<EOF
[
]
EOF
    vpc_id = "${aws_vpc.default.id}"
    lb_arn = "${aws_lb.openfaas.arn}"
    lb_port = "9090"
    health_check_path = "/graph"
}

resource "aws_security_group" "prometheus" {
    name = "${var.namespace}.prometheus"
    description = "prometheus security group."
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-prometheus", var.namespace)}"
    }
}

resource "aws_security_group_rule" "prometheus_ingress_alb" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.prometheus.id}"
    source_security_group_id = "${aws_security_group.alb.id}"
    from_port                = 9090
    to_port                  = 9090
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "prometheus_ingress_gateway" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.prometheus.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 9090
    to_port                  = 9090
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "prometheus_egress_alertmanager" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.prometheus.id}"
    source_security_group_id = "${aws_security_group.alertmanager.id}"
    from_port                = 9093
    to_port                  = 9093
    protocol                 = "tcp"
}

resource "aws_iam_role" "prometheus_role" {
    name = "${var.namespace}-prometheus-provider-role"
    assume_role_policy = "${file("${path.module}/data/iam/ecs-task-assumerole.json")}"
}

resource "aws_iam_role_policy" "prometheus_role_policy" {
    name = "${var.namespace}-prometheus-role-policy"
    role = "${aws_iam_role.prometheus_role.id}"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    ${file("${path.module}/data/iam/log-policy.json")}
  ]
}
EOF
}
