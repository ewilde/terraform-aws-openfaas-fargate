provider "aws" {
    region = "${var.aws_region}"
    version = "~> 1.41.0"
}

provider "acme" {
    version = "~> 1.0"
    server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
