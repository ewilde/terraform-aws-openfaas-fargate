variable "name" { description = "name of the service and task" }
variable "ecs_cluster_name" { description = "name of the ecs cluster"}
variable "allowed_subnets" { description = "list of subnets to attach service to" type = "list"}
variable "security_groups" { description = "list of security groups to assign to the new service" type = "list"}
variable "desired_count" { description = "service desired count"}
variable "task_arn" { }
variable "namespace" {}
variable "namespace_id" {}
variable "aws_region" {}
