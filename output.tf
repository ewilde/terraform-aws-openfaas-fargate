output "bastion_ip" {
    value = "${aws_instance.bastion.*.public_ip}"
}

output "servicebox_ip" {
    value = "${aws_instance.service.*.private_ip}"
}
