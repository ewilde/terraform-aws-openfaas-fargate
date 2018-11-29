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

output "openfass_uri" {
    value = "https://gateway.${var.route53_zone_name}/ui/"
}

output "login" {
    value = "echo -n \"${random_string.basic_auth_password.result}\" | faas-cli login --gateway https://${aws_lb.openfaas.dns_name} --username=admin --password-stdin --tls-no-verify"
}

output "login_secure" {
    value = "echo -n \"${random_string.basic_auth_password.result}\" | faas-cli login --gateway https://gateway.${var.route53_zone_name} --username=admin --password-stdin"
}
