resource "aws_ecs_cluster" "openfaas" {
    name = "${var.ecs_cluster_name}"
}

resource "aws_ecs_service" "gateway" {
    name             = "gateway"
    cluster          = "${var.ecs_cluster_name}"
    task_definition  = "${aws_ecs_task_definition.gateway.arn}"
    launch_type      = "FARGATE"
    desired_count    = 1

    network_configuration {
        subnets          = ["${aws_subnet.external.*.id}"]
        security_groups  = ["${aws_security_group.service.id}"]
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
      "value": "${aws_service_discovery_service.nats.name}.${aws_service_discovery_private_dns_namespace.openfaas.name}"
    }
  ],
  "essential": true,
  "image": "functions/gateway:0.8.2",
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

resource "aws_iam_role" "ecs_role" {
    assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_role_policy" {
    name   = "openfaas-task-role"
    role = "${aws_iam_role.ecs_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

module "nats" {
    source                        = "./service-internal"
    name                          = "nats"
    ecs_cluster_name              = "${var.ecs_cluster_name}"
    aws_region                    = "${var.aws_region}"
    desired_count                 = "1"
    security_groups               = ["${aws_security_group.service.id}"]
    allowed_subnets               = ["${aws_subnet.internal.*.id}"]
    namespace                     = "${var.namespace}"
    service_discovery_service_arn = "${aws_service_discovery_service.nats.arn}"
    task_image                    = "ewilde/nats-streaming"
    task_image_version            = "0.9.2-linux"
    task_role_arn                 = "${aws_iam_role.ecs_role.arn}"
    task_ports                    = "[{\"containerPort\":8222,\"hostPort\":8222}]"
}


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
