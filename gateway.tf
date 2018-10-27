
resource "aws_ecs_service" "gateway" {
    name             = "gateway"
    cluster          = "${aws_ecs_cluster.openfaas.name}"
    task_definition  = "${aws_ecs_task_definition.gateway.arn}"
    launch_type      = "FARGATE"
    desired_count    = 1

    network_configuration {
        subnets          = ["${aws_subnet.external.*.id}"]
        security_groups  = ["${aws_security_group.gateway.id}"]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = "${aws_lb_target_group.gateway.arn}"
        container_name = "gateway"
        container_port = 8080
    }

    service_registries {
        registry_arn = "${aws_service_discovery_service.gateway.arn}"
    }

    lifecycle {
        ignore_changes = ["desired_count"]
    }

    depends_on = ["aws_lb_listener.gateway"]
}

resource "aws_ecs_task_definition" "gateway" {
    family                   = "gateway"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    task_role_arn            = "${aws_iam_role.gateway_role.arn}"
    execution_role_arn       = "${aws_iam_role.gateway_role.arn}"
    cpu                      = "256"
    memory                   = "512"
    container_definitions    = <<DEFINITION
[
  {
      "name": "gateway",
      "cpu": 128,
      "environment": [
        {
          "name": "functions_provider_url",
          "value": "http://localhost:8081/"
        },
        {
          "name": "faas_nats_address",
          "value": "${module.nats.service_discovery_name}.${aws_service_discovery_private_dns_namespace.openfaas.name}"
        },
        {
          "name": "faas_prometheus_host",
          "value": "${module.prometheus.service_discovery_name}.${aws_service_discovery_private_dns_namespace.openfaas.name}"
        },
        {
          "name": "faas_nats_port",
          "value": "4222"
        },
        {
          "name": "basic_auth",
          "value": "true"
        }
      ],
      "volumesFrom": [
        {
          "sourceContainer": "gateway-kms"
        }
      ],
      "essential": true,
      "image": "openfaas/gateway:0.9.6",
      "memory": 64,
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
      "healthCheck": {
        "retries": 1,
        "command": ["CMD-SHELL", "cat /run/secrets/basic-auth-password || exit 1" ],
        "timeout": 3,
        "interval": 5,
        "startPeriod": 5
      }
  },
   {
      "name": "fargate-provider",
      "cpu": 64,
      "memory": 64,
      "image": "openfaas/gateway:0.9.6",
      "environment": [
          {
             "name"  : "port",
             "value" : "8081"
          },
          {
             "name"  : "subnet_ids",
             "value" : "${join(",", aws_subnet.internal.*.id)}"
          },
          {
             "name"  : "security_group_id",
             "value" : "${aws_security_group.service.id}"
          }

        ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.gateway_log.name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "gateway"
        }
      },
      "healthCheck": {
        "retries": 1,
        "command": ["CMD-SHELL", "cat /run/secrets/basic-auth-password || exit 1" ],
        "timeout": 3,
        "interval": 5,
        "startPeriod": 5
      }
  },
  {
      "name": "gateway-kms",
      "cpu": 64,
      "memory": 32,
      "environment": [
        {
          "name": "SECRETS",
          "value": "basic-auth-user,basic-auth-password"
        }
      ],
      "essential": true,
      "image": "ewilde/kms-template:latest",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.gateway_log_kms.name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "gateway-kms"
        }
      },
      "healthCheck": {
        "retries": 1,
        "command": ["CMD-SHELL", "cat /run/secrets/basic-auth-password || exit 1" ],
        "timeout": 3,
        "interval": 5,
        "startPeriod": 5
      }
  }
]
DEFINITION
    depends_on = [
        "aws_secretsmanager_secret_version.basic_auth_password",
        "aws_secretsmanager_secret_version.basic_auth_user"
    ]
}

resource "aws_cloudwatch_log_group" "gateway_log" {
    name = "${var.namespace}-gateway"
}

resource "aws_cloudwatch_log_group" "gateway_log_kms" {
    name = "${var.namespace}-gateway-kms"
}

resource "aws_security_group" "gateway" {
    name = "${var.namespace}.gateway"
    description = "gateway security group. allows traffic from alb and to internal subnet"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-gateway", var.namespace)}"
    }
}

resource "aws_service_discovery_service" "gateway" {
    name = "gateway"
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

resource "aws_security_group_rule" "gateway_ingress_alb" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.alb.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway_ingress_prometheus" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.prometheus.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway_ingress_nats_queue_worker" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.nats_queue_worker.id}"
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "gateway_ingress_alertmanager" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.alertmanager.id}"
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

resource "aws_security_group_rule" "gateway_egress_prometheus" {
    type                     = "egress"
    security_group_id        = "${aws_security_group.gateway.id}"
    source_security_group_id = "${aws_security_group.prometheus.id}"
    from_port                = 9090
    to_port                  = 9090
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

resource "random_string" "basic_auth_password" {
    length  = 32
    special = false
}

resource "aws_secretsmanager_secret" "basic_auth_password" {
    name                    = "basic-auth-password"
    recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "basic_auth_password" {
    secret_id     = "${aws_secretsmanager_secret.basic_auth_password.id}"
    secret_string = "${random_string.basic_auth_password.result}"
}

resource "aws_secretsmanager_secret" "basic_auth_user" {
    name                    = "basic-auth-user"
    recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "basic_auth_user" {
    secret_id     = "${aws_secretsmanager_secret.basic_auth_user.id}"
    secret_string = "admin"
}

resource "aws_iam_role" "gateway_role" {
    name = "${var.namespace}-gateway-role"
    assume_role_policy = "${file("${path.module}/data/iam/ecs-task-assumerole.json")}"
}

resource "aws_iam_role_policy" "gateway_role_policy" {
    name = "${var.namespace}-gateway-role-policy"
    role = "${aws_iam_role.gateway_role.id}"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    ${file("${path.module}/data/iam/log-policy.json")},
    {
        "Effect": "Allow",
        "Action": [
            "secretsmanager:GetSecretValue"
        ],
        "Resource": [
            "${aws_secretsmanager_secret.basic_auth_user.id}",
            "${aws_secretsmanager_secret.basic_auth_password.id}"
        ]
    }
  ]
}
EOF
}
