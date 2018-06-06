resource "aws_ecs_cluster" "openfaas" {
    name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_service" "gateway" {
    name = "openfaas-core"
    cluster = "${var.ecs_cluster_name}"
    task_definition  = "${aws_ecs_task_definition.gateway.arn}"

    launch_type      = "FARGATE"
    desired_count = 1

    network_configuration {
        subnets = ["${aws_subnet.default.*.id}"]
    }

    load_balancer {
        target_group_arn = "${aws_alb_target_group.openfaas.arn}"
        container_name = "gateway"
        container_port = 8080
    }

    service_registries {
        registry_arn = "${aws_service_discovery_service.gateway.arn}"
        port         = "8080"
    }

    lifecycle {
        ignore_changes = ["desired_count"]
    }
}

resource "aws_ecs_task_definition" "gateway" {
    family  = "gateway"

    container_definitions = <<DEFINITION
[
  {
  "cpu": 256,
  "environment": [
    {
      "name": "SECRET",
      "value": "KEY"
    }
  ],
  "essential": true,
  "image": "functions/gateway:0.8.2",
  "memory": 256,
  "memoryReservation": 64,
  "portMappings": [
    {
      "containerPort": 8080,
      "hostPort": 8080
    }
  ],
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${aws_cloudwatch_log_group.gateway_log.name}",
      "awslogs-region": "${var.aws_region}",
      "awslogs-stream-prefix": "gateway"
    }
  },
  "name": "gateway"
}
]
DEFINITION
}

resource "aws_cloudwatch_log_group" "gateway_log" {
    name = "${var.namespace}-gateway"
}
