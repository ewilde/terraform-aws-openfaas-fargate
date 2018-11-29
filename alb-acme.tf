resource "tls_private_key" "private_key" {
    algorithm = "RSA"
    count = "${var.acme_enabled}"
}

resource "acme_registration" "reg" {
    account_key_pem = "${tls_private_key.private_key.0.private_key_pem}"
    email_address   = "${var.acme_email_address}"
    count           = "${var.acme_enabled}"
}

resource "acme_certificate" "acme" {
    account_key_pem           = "${acme_registration.reg.0.account_key_pem}"
    common_name               = "${aws_route53_record.main.fqdn}"
    count                     = "${var.acme_enabled}"

    dns_challenge {
        provider = "route53"
    }
}

resource "aws_iam_server_certificate" "acme" {
    name              = "acme-certificate-${md5(acme_certificate.acme.0.certificate_pem)}"
    certificate_body  = "${acme_certificate.acme.0.certificate_pem}"
    private_key       = "${acme_certificate.acme.0.private_key_pem}"
    certificate_chain = "${acme_certificate.acme.0.issuer_pem}"
    count             = "${var.acme_enabled}"

    lifecycle {
        create_before_destroy = true
    }
}

data "aws_route53_zone" "main" {
    name  = "${var.route53_zone_name}"
    count = "${var.acme_enabled}"
}

resource "aws_route53_record" "main" {
    name = "gateway"
    zone_id = "${data.aws_route53_zone.main.id}"
    type    = "A"
    count   = "${var.acme_enabled}"
    alias {
        name                   = "${aws_lb.openfaas.dns_name}"
        zone_id                = "${aws_lb.openfaas.zone_id}"
        evaluate_target_health = false
    }
}

