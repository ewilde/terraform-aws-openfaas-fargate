variable "name" { description = "name of the service and task" }
variable "ecs_cluster_name" { description = "name of the ecs cluster"}
variable "allowed_subnets" { description = "list of subnets to attach service to" type = "list"}
variable "security_groups" { description = "list of security groups to assign to the new service" type = "list"}
variable "desired_count" { description = "service desired count"}
variable "task_role_arn" {}
variable "task_cpu" { default = "256" }
variable "task_env_vars" {description = "The raw json of the task env vars" default = "[]"}
variable "task_image" {}
variable "task_image_version" {}
variable "task_memory" { default = "64" }
variable "task_ports" { default = "[]" }
variable "lb_port" {}
variable "lb_arn" {}
variable "health_check_path" {}
variable "vpc_id" {}
variable "task_health_check_command" { default = "[\"CMD-SHELL\",\"ls\"]" }
variable "task_command" { default = "[]" }
variable "namespace" {}
variable "namespace_id" {}
variable "aws_region" {}
