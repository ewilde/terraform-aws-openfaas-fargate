resource "aws_ecs_cluster" "openfaas" {
    name = "${var.ecs_cluster_name}"
}

resource "aws_iam_role" "ecs_role" {
    assume_role_policy = "${file("${path.module}/data/iam/ecs-task-assumerole.json")}"
}

resource "aws_iam_role_policy" "ecs_role_policy" {
    name   = "openfaas-task-role"
    role = "${aws_iam_role.ecs_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    ${file("${path.module}/data/iam/log-policy.json")}
  ]
}
EOF
}

