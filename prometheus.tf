resource "aws_ecs_service" "prometheus" {
    name             = "prometheus"
    cluster          = "${aws_ecs_cluster.openfaas.name}"
    task_definition  = "${aws_ecs_task_definition.prometheus.arn}"
    launch_type      = "FARGATE"
    desired_count    = 1

    network_configuration {
        subnets          = ["${aws_subnet.internal.*.id}"]
        security_groups  = ["${aws_security_group.prometheus.id}"]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = "${aws_lb_target_group.prometheus.arn}"
        container_name = "prometheus"
        container_port = 9090
    }

    service_registries {
        registry_arn = "${aws_service_discovery_service.prometheus.arn}"
    }

    lifecycle {
        ignore_changes = ["desired_count"]
    }

    depends_on = ["aws_lb_listener.prometheus"]
}

resource "aws_ecs_task_definition" "prometheus" {
    family                   = "prometheus"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    task_role_arn            = "${aws_iam_role.ecs_role.arn}"
    execution_role_arn       = "${aws_iam_role.ecs_role.arn}"
    cpu                      = "256"
    memory                   = "512"
    container_definitions    = <<DEFINITION
[
  {
  "cpu": 256,
  "essential": true,
  "image": "ewilde/prometheus:v2.3.1",
  "memory": 64,
  "portMappings": [
    {
      "containerPort": 9090,
      "hostPort": 9090
    }
  ],
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${aws_cloudwatch_log_group.prometheus_log.name}",
      "awslogs-region": "${var.aws_region}",
      "awslogs-stream-prefix": "prometheus"
    }
  },
  "name": "prometheus"
}
]
DEFINITION
}

resource "aws_cloudwatch_log_group" "prometheus_log" {
    name = "${var.namespace}-prometheus"
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
