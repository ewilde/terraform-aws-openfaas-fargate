module "nats" {
    source                        = "./service-internal-no-task"
    name                          = "nats"
    ecs_cluster_name              = "${aws_ecs_cluster.openfaas.name}"
    aws_region                    = "${var.aws_region}"
    desired_count                 = "1"
    security_groups               = ["${aws_security_group.nats.id}", "${aws_security_group.nats_queue_worker.id}", "${aws_security_group.service.id}"]
    allowed_subnets               = ["${aws_subnet.internal.*.id}"]
    namespace                     = "${var.namespace}"
    namespace_id                  = "${aws_service_discovery_private_dns_namespace.openfaas.id}"
    task_arn                      = "${aws_ecs_task_definition.nats.arn}"
}

resource "aws_ecs_task_definition" "nats" {
    family                   = "nats"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    task_role_arn            = "${aws_iam_role.ecs_role.arn}"
    execution_role_arn       = "${aws_iam_role.ecs_role.arn}"
    cpu                      = "256"
    memory                   = "512"
    container_definitions    = <<DEFINITION
[
  {
    "name": "nats",
    "memory": 64,
    "cpu": 128,
    "image": "ewilde/nats-streaming:0.11.2",
    "environment": [],
    "command": [
        "--store",
        "memory",
        "--cluster_id",
        "faas-cluster"
    ],
    "essential": true,
    "portMappings": [
        {"containerPort":4222,"hostPort":4222},
        {"containerPort":8222,"hostPort":8222}
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.nats.name}",
          "awslogs-region": "${var.aws_region}",
        }
    },
    "healthCheck": {
        "retries": 1,
        "command": ["CMD-SHELL","ls"],
        "timeout": 3,
        "interval": 5,
        "startPeriod": 5
    }
  },
  {
    "name": "nats-queue-worker",
    "memory": 64,
    "cpu": 128,
    "image": "ewilde/queue-worker:latest",
    "environment": [
      {
        "name": "faas_nats_address",
        "value": "localhost"
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
    ],
    "essential": true,
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.nats_queue_worker.name}",
          "awslogs-region": "${var.aws_region}",
        }
    },
    "healthCheck": {
        "retries": 1,
        "command": ["CMD-SHELL","ls"],
        "timeout": 3,
        "interval": 5,
        "startPeriod": 5
    }
  }
]
DEFINITION
}

resource "aws_cloudwatch_log_group" "nats" {
    name = "${var.namespace}-nats"
}

resource "aws_cloudwatch_log_group" "nats_queue_worker" {
    name = "${var.namespace}-nats-queue-worker"
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



resource "aws_security_group" "nats_queue_worker" {
    name = "${var.namespace}.nats-queue-worker"
    description = "Security rules for the nats queue worker"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-nats-queue-worker", var.namespace)}"
    }
}

resource "aws_security_group_rule" "nats_queue_worker_egress_gateway" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.nats_queue_worker.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}
