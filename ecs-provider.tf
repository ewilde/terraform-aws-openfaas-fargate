module "ecs_provider" {
    source                        = "./service-internal"
    name                          = "ecs-provider"
    ecs_cluster_name              = "${var.ecs_cluster_name}"
    aws_region                    = "${var.aws_region}"
    desired_count                 = "1"
    security_groups               = ["${aws_security_group.service.id}", "${aws_security_group.ecs_provider.id}"]
    allowed_subnets               = ["${aws_subnet.internal.*.id}"]
    namespace                     = "${var.namespace}"
    service_discovery_service_arn = "${aws_service_discovery_service.ecs_provider.arn}"
    task_image                    = "ewilde/faas-ecs"
    task_image_version            = "latest"
    task_role_arn                 = "${aws_iam_role.ecs_provider_role.arn}"
    task_ports                    = "[{\"containerPort\":8081,\"hostPort\":8081}]"
    task_env_vars                 = <<EOF
[
  {
     "name"  : "port",
     "value" : "8081"
  },
  {
     "name"  : "subnet_ids",
     "value" : "${join(",", aws_subnet.internal.*.id)}"
  }

]
EOF
}

resource "aws_service_discovery_service" "ecs_provider" {
    name = "ecs"
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

resource "aws_security_group" "ecs_provider" {
    name = "${var.namespace}.ecs-provider"
    description = "Security rules for the ecs provider"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${format("%s-ecs-provider", var.namespace)}"
    }
}

resource "aws_security_group_rule" "ecs_provider_ingress_gateway" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.ecs_provider.id}"
    source_security_group_id = "${aws_security_group.gateway.id}"
    from_port                = 8081
    to_port                  = 8081
    protocol                 = "tcp"
}

resource "aws_security_group_rule" "ecs-provider_ingress_bastion" {
    type                     = "ingress"
    security_group_id        = "${aws_security_group.ecs_provider.id}"
    source_security_group_id = "${aws_security_group.bastion.id}"
    from_port                = 8081
    to_port                  = 8081
    protocol                 = "tcp"
    count                    = "${var.debug}"
}

resource "aws_iam_role" "ecs_provider_role" {
    name = "${var.namespace}-ecs-provider-role"
    assume_role_policy = "${file("${path.module}/data/iam/ecs-task-assumerole.json")}"
}

resource "aws_iam_role_policy" "ecs_provider_role_policy" {
    name = "${var.namespace}-ecs-provider-role-policy"
    role = "${aws_iam_role.ecs_provider_role.id}"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    ${file("${path.module}/data/iam/log-policy.json")},
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "servicediscovery:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}
