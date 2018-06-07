
resource "aws_vpc" "default" {
    cidr_block           = "${var.vpc_cidr_block}"
    enable_dns_hostnames = true

    tags {
        "Name" = "${var.namespace}"
    }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"

    tags {
        "Name" = "${var.namespace}"
    }
}

resource "aws_nat_gateway" "default" {
    count         = "${length(var.external_subnets)}"
    allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
    subnet_id     = "${element(aws_subnet.external.*.id, count.index)}"

    tags {
        Name = "${var.namespace}"
    }
}

resource "aws_eip" "nat" {
    count         = "${length(var.external_subnets)}"
    vpc           = true

    tags {
        Name = "${var.namespace}"
    }
}

resource "aws_route_table" "internal" {
    count  = "${length(var.internal_subnets)}"
    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "${var.namespace}-${format("internal-%03d", count.index+1)}"
    }
}

resource "aws_route_table_association" "internal" {
    count          = "${length(var.internal_subnets)}"
    subnet_id      = "${element(aws_subnet.internal.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.internal.*.id, count.index)}"
}

resource "aws_route" "internal" {
    count                  = "${length(compact(var.internal_subnets))}"
    route_table_id         = "${element(aws_route_table.internal.*.id, count.index)}"
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = "${element(aws_nat_gateway.default.*.id, count.index)}"
}

resource "aws_route_table" "external" {
    vpc_id = "${aws_vpc.default.id}"
    count  = "${length(var.internal_subnets)}"

    tags {
        Name = "${var.namespace}-${format("external-%03d", count.index+1)}"
    }
}

resource "aws_route" "external" {
    count                  = "${length(compact(var.external_subnets))}"
    route_table_id         = "${element(aws_route_table.external.*.id, count.index)}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_route_table_association" "external" {
    count          = "${length(var.external_subnets)}"
    subnet_id      = "${element(aws_subnet.external.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.external.*.id, count.index)}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "external" {
    count                   = "${length(var.external_subnets)}"
    vpc_id                  = "${aws_vpc.default.id}"
    availability_zone       = "${var.azs[count.index]}"
    cidr_block              = "${var.external_subnets[count.index]}"
    map_public_ip_on_launch = true

    tags {
        "Name" = "${var.namespace}-external"
    }
}
resource "aws_subnet" "internal" {
    count                   = "${length(var.internal_subnets)}"
    vpc_id                  = "${aws_vpc.default.id}"
    availability_zone       = "${var.azs[count.index]}"
    cidr_block              = "${var.internal_subnets[count.index]}"
    map_public_ip_on_launch = false

    tags {
        "Name" = "${var.namespace}-internal"
    }
}
