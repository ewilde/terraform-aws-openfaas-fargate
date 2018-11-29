resource "aws_ecs_service" "main" {
    name             = "${var.name}"
    cluster          = "${var.ecs_cluster_name}"
    task_definition  = "${aws_ecs_task_definition.main.arn}"
    launch_type      = "FARGATE"
    desired_count    = "${var.desired_count}"

    network_configuration {
        subnets          = ["${var.allowed_subnets}"]
        security_groups  = ["${var.security_groups}"]
        assign_public_ip = false
    }

    service_registries {
        registry_arn = "${aws_service_discovery_service.main.arn}"
    }

    load_balancer {
        target_group_arn = "${aws_lb_target_group.main.arn}"
        container_name = "${var.name}"
        container_port = "${var.lb_port}"
    }

    lifecycle {
        ignore_changes = ["desired_count"]
    }

    depends_on = ["aws_lb_listener.main"]
}

resource "aws_service_discovery_service" "main" {
    name = "${var.name}"
    dns_config {
        namespace_id = "${var.namespace_id}"
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

resource "aws_lb_target_group" "main" {
    name        = "${var.namespace}-${var.name}"
    port        = "${var.lb_port}"
    protocol    = "HTTP"
    vpc_id      = "${var.vpc_id}"

    target_type = "ip"
    health_check {
        path    = "${var.health_check_path}"
        matcher = "200"
    }
}

resource "aws_lb_listener" "main" {
    load_balancer_arn = "${var.lb_arn}"
    port              = "${var.lb_port}"
    protocol          = "HTTP"
    default_action {
        target_group_arn = "${aws_lb_target_group.main.arn}"
        type             = "forward"
    }
}

resource "aws_ecs_task_definition" "main" {
    family                   = "${var.name}"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    task_role_arn            = "${var.task_role_arn}"
    execution_role_arn       = "${var.task_role_arn}"
    cpu                      = "256"
    memory                   = "512"
    container_definitions    = <<DEFINITION
[
  {
    "cpu": ${var.task_cpu},
    "environment": ${var.task_env_vars},
    "command": ${var.task_command},
    "essential": true,
    "image": "${var.task_image}:${var.task_image_version}",
    "memory": ${var.task_memory},
    "name": "${var.name}",
    "portMappings": ${var.task_ports},
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.main.name}",
          "awslogs-region": "${var.aws_region}",
        }
    },
    "healthCheck": {
        "retries": 1,
        "command": ${var.task_health_check_command},
        "timeout": 3,
        "interval": 5,
        "startPeriod": 5
    }
}
]
DEFINITION
}

resource "aws_cloudwatch_log_group" "main" {
    name = "${var.namespace}-${var.name}"
}
