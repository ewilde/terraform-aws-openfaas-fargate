variable "aws_region" {}

variable "vpc_cidr_block" {
    default = "10.0.0.0/16"
}

variable "azs" {
    type    = "list"
    default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "private_subnets" {
    type    = "list"
    default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "namespace" {
    default     = "openfaas"
    description = "namespace is used to distinguish different instances of installing this module."
}

variable "ecs_cluster_name" {
    default = "openfaas"
}
