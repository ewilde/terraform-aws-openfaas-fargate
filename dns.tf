resource "aws_service_discovery_private_dns_namespace" "openfaas" {
    name = "openfaas.local"
    description = "example"
    vpc = "${aws_vpc.default.id}"
}

resource "aws_service_discovery_service" "gateway" {
    name = "gateway"
    dns_config {
        namespace_id = "${aws_service_discovery_private_dns_namespace.openfaas.id}"
        dns_records {
            ttl = 10
            type = "A"
        }
        routing_policy = "MULTIVALUE"
    }
}
