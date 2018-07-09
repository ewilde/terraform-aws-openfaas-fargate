module "prometheus" {
    source                        = "./service-internal"
    name                          = "prometheus"
    ecs_cluster_name              = "${var.ecs_cluster_name}"
    aws_region                    = "${var.aws_region}"
    desired_count                 = "1"
    security_groups               = ["${aws_security_group.service.id}", "${aws_security_group.ecs_provider.id}"]
    allowed_subnets               = ["${aws_subnet.internal.*.id}"]
    namespace                     = "${var.namespace}"
    service_discovery_service_arn = "${aws_service_discovery_service.prometheus.arn}"
    task_image                    = "ewilde/prometheus"
    task_image_version            = "v2.3.1"
    task_role_arn                 = "${aws_iam_role.prometheus_role.arn}"
    task_ports                    = "[{\"containerPort\":9090,\"hostPort\":9090}]"
}

resource "aws_service_discovery_service" "prometheus" {
    name = "prometheus"
    dns_config {
        namespace_id = "${aws_service_discovery_private_dns_namespace.openfaas.id}"
        dns_records {
            ttl = 10
            type = "A"
        }
        routing_policy = "MULTIVALUE"
    }

    health_check_custom_config {
        failure_threshold = 1
    }
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
