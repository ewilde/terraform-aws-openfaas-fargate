output "bastion_ip" {
    value = "${aws_instance.bastion.*.public_ip}"
}

output "servicebox_ip" {
    value = "${aws_instance.service.*.private_ip}"
}

output "service_security_group" {
    value = "${aws_security_group.service.id}"
}

output "alb_uri" {
    value = "${aws_lb.openfaas.dns_name}"
}
