resource "aws_service_discovery_private_dns_namespace" "openfaas" {
    name = "openfaas.local"
    description = "example"
    vpc = "${aws_vpc.default.id}"
}
