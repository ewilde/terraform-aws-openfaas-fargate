resource "aws_security_group" "allow_openfaas" {
    name = "${var.namespace}.allow_openfaas"
    description = "Allow OpenFaaS, Nomad and SSH Externally, everything on internal VPC"
    vpc_id = "${aws_vpc.default.id}"

    ingress {
        from_port = 8080
        to_port = 8081
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"]
    }

    # Allow all traffic within the vpc
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["${var.vpc_cidr_block}"]
    }

    # Allow all outbound traffic
    egress {
        from_port   = 443
        to_port     = 442
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
