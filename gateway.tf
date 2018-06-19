
resource "aws_ecs_service" "gateway" {
    name             = "gateway"
    cluster          = "${var.ecs_cluster_name}"
    task_definition  = "${aws_ecs_task_definition.gateway.arn}"
    launch_type      = "FARGATE"
    desired_count    = 1

    network_configuration {
        subnets          = ["${aws_subnet.external.*.id}"]
        security_groups  = ["${aws_security_group.gateway.id}"]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = "${aws_lb_target_group.openfaas.arn}"
        container_name = "gateway"
        container_port = 8080
    }

    service_registries {
        registry_arn = "${aws_service_discovery_service.gateway.arn}"
    }

    lifecycle {
        ignore_changes = ["desired_count"]
    }

    depends_on = ["aws_lb_listener.openfaas"]
}

resource "aws_ecs_task_definition" "gateway" {
    family                   = "gateway"
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
  "environment": [
    {
      "name": "functions_provider_url",
      "value": "http://${aws_service_discovery_service.ecs_provider.name}.${aws_service_discovery_private_dns_namespace.openfaas.name}:8081/"
    },
    {
      "name": "faas_nats_address",
      "value": "${aws_service_discovery_service.nats.name}.${aws_service_discovery_private_dns_namespace.openfaas.name}"
    },
    {
      "name": "faas_nats_port",
      "value": "4222"
    }
  ],
  "essential": true,
  "image": "ewilde/openfaas-gateway:latest-dev",
  "memory": 64,
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

resource "aws_security_group" "gateway" {
    name = "${var.namespace}.gateway"
    description = "gateway security group. allows traffic from alb and to internal subnet"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-gateway", var.namespace)}"
    }
}

resource "aws_security_group_rule" "gateway_ingress_alb" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.alb.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway_ingress_bastion" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.bastion.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
    count                    = "${var.debug}"
}

resource "aws_security_group_rule" "gateway_egress_nats" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.nats.id}"
    from_port                = 4222
    to_port                  = 4222
    protocol                 = "all"
}

resource "aws_security_group_rule" "gateway_egress_nats_management" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.nats.id}"
    from_port                = 8222
    to_port                  = 8222
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway_egress_ecs" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.ecs_provider.id}"
    from_port                = 8081
    to_port                  = 8081
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway_egress_functions" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.service.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway_egress_http" {
    type               = "egress"
    security_group_id  = "${aws_security_group.gateway.id}"
    from_port          = 80
    to_port            = 80
    protocol           = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "gateway_egress_https" {
    type               = "egress"
    security_group_id  = "${aws_security_group.gateway.id}"
    from_port          = 443
    to_port            = 443
    protocol           = "tcp"
    cidr_blocks        = ["0.0.0.0/0"]
}
