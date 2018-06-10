module "bastion_ami" {
    source = "../modules/ami"
    name   = "amazon_linux"
}

resource "aws_instance" "bastion" {
    ami                         = "${module.bastion_ami.ami_id}"
    source_dest_check           = false
    instance_type               = "t2.micro"
    subnet_id                   = "${element("${aws_subnet.external.*.id}", 0)}"
    key_name                    = "${var.bastion_keypair_name}"
    vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
    monitoring                  = true
    user_data                   = <<EOF
    ${file(format("%s/data/userdata/bastion.user_data.sh", path.module))}
    ${data.template_file.bastion_userdata.rendered}
  EOF
    associate_public_ip_address = true
    tags {
        Name        = "${var.stack_name}-bastion"
        Environment = "${var.environment}"
    }

    depends_on = ["aws_key_pair.bastion_ssh", "aws_internet_gateway.main"]
}

resource "aws_key_pair" "bastion_ssh" {
    key_name = "${var.bastion_keypair_name}"
    public_key = "${file("${path.module}/keys/${module.environment.bastion_keyfile_name}.pub")}"
}
