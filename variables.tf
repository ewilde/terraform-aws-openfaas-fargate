variable "aws_region"   {}
variable "developer_ip" { default = "" description = "Required if using debugging" }
variable "debug" { default = "0" description = "Set to 1 to create debugging bastion on external subnet and instance on internal subnet" }
variable "vpc_cidr_block" {
    default = "10.0.0.0/16"
}

variable "azs" {
    type    = "list"
    default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "external_subnets" {
    type    = "list"
    default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "internal_subnets" {
    type    = "list"
    default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "namespace" {
    default     = "openfaas"
    description = "namespace is used to distinguish different instances of installing this module."
}

variable "ecs_cluster_name" {
    default = "openfaas"
}

variable "bastion_keypair_name" {
    default = "openfaas"
}

variable "self_signed_enabled" {
    default = 1
}

variable "acme_enabled" {
    default = 0
}

variable "acme_email_address" {
    default = "nobody@example.com"
}

variable "acme_domain_name" {
    default = ""
}

variable "alb_logs_bucket" {}
