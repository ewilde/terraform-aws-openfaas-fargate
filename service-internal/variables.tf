variable "name" { description = "name of the service and task" }
variable "ecs_cluster_name" { description = "name of the ecs cluster"}
variable "allowed_subnets" { description = "list of subnets to attach service to" type = "list"}
variable "security_groups" { description = "list of security groups to assign to the new service" type = "list"}
variable "service_discovery_service_arn" { description = "arn of the service discovery"}
variable "desired_count" { description = "service desired count"}
variable "task_role_arn" {}
variable "task_cpu" { default = "256" }
variable "task_env_vars" {description = "The raw json of the task env vars" default = "[]"}
variable "task_image" {}
variable "task_image_version" {}
variable "task_memory" { default = "64" }
variable "task_ports" { default = "[]" }
variable "namespace" {}
variable "aws_region" {}
