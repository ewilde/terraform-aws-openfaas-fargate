resource "aws_ecs_service" "main" {
    name             = "${var.name}"
    cluster          = "${var.ecs_cluster_name}"
    task_definition  = "${var.task_arn}"
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

    lifecycle {
        ignore_changes = ["desired_count"]
    }
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
