## Overview
<img align="right" title="diagram of the openfaas on fargate architecture" width="400" src="docs/architecture.png" alt="Openfaas for fargate overview" />

* [Installing](#installing)
* [Uninstalling](#uninstalling)

## <a name="installing"></a>Installing
1. **Install terraform**

**_Mac_**: `brew install terraform`

**_Linux_**: 
```
wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
unzip terraform_0.11.7_linux_amd64.zip
sudo mv terraform /usr/local/bin
terraform --version
```

2. **Create terraform.tfvars**

You will need to create a new file in the root of this repo called `terraform.tfvars`
which configures variables used to install `faas-ecs`  

| Name                | Description                                                                                                                      |
|---------------------|----------------------------------------------------------------------------------------------------------------------------------|
| acme_enabled        | (Recommend)`1` to use the official [acme]() terraform provider to create TLS certificates. Defaults to `0`                       |
| acme_email_address  | (Recommend) Email address used to register TLS account, used in conjunction with `acme_enabled`                                  |
| aws_region          | (Required) The aws region to create the openfaas ecs cluster in                                                                  |
| alb_logs_bucket     | (Required) S3 bucket to store alb logs                                                                                           |
| debug               | (Optional) `1` to create an ec2 bastion in the external subnet and a test instance in the internal subnet. Defaults to `0`       |
| developer_ip        | your ip address, used to whitelist incoming ssh to the bastion, debug is enabled                                                 |
| route53_zone_name   | (Recommended) a route 53 zone to create DNS records for the OpenFaaS gateway, i.e. openfaas.example.com, requires `acme_enabled` |
| self_signed_enabled | (Not recommended) Use a self-signed TLS certificate for the OpenFaaS gateway if not using `acme_enabled`. Defaults to `0`        |



**_Example file_**
```
cat > ./terraform.tfvars <<EOF
acme_enabled           = "1"
acme_email_address     = "ewilde@gmail.com"
alb_logs_bucket        = "ewilde-logs"
aws_region             = "eu-west-1"
debug                  = "1"
developer_ip           = "31.53.195.58"
route53_zone_name      = "openfaas.edwardwilde.com"
self_signed_enabled    = "0"
EOF
```
3. **Create a public key for ssh**

> Ssh access is only required if `debug = "1"`, however the ssh key is still required for the 
install to work even if debug disabled. To create the key run:

`make keys`

4. Create bucket for alb logs
If you don't already have a bucket, please create the bucket you listed in your `terraform.tfvars` in the variable
`alb_logs_bucket`

i.e. `aws s3api create-bucket --bucket ewilde-logs --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1`

4. **Run terraform**

`make`

### Known issue
If you get the following error:
```
Error: Error applying plan:

2 error(s) occurred:

* module.ecs_provider.aws_ecs_service.main: 1 error(s) occurred:

* aws_ecs_service.main: InvalidParameterException: Unable to assume the service linked role. Please verify that the ECS service linked role exists.
	status code: 400, request id: d967b493-82f9-11e8-9d63-f5180ba0fbef "ecs-provider"
* module.nats.aws_ecs_service.main: 1 error(s) occurred:

* aws_ecs_service.main: InvalidParameterException: Unable to assume the service linked role. Please verify that the ECS service linked role exists.
	status code: 400, request id: dab962b7-82f9-11e8-8cc5-29d47e720a04 "nats"

Terraform does not automatically rollback in the face of errors.
Instead, your Terraform state file has been partially updated with
any resources that successfully completed. Please address the error
above and apply again to incrementally change your infrastructure.

```

Please just re-run `make`, this is an eventual consistency problem see #4

## <a name="uninstalling"></a>Uninstalling

1. Run `make uninstall`
2. Patiently wait about `5-10 minutes`

### Known issue
```Error applying plan:

1 error(s) occurred:

* aws_service_discovery_private_dns_namespace.openfaas (destroy): 1 error(s) occurred:
```

To resolve this problem manually delete all the service registrations

`aws servicediscovery list-services | jq '.Services[].Id' -r | xargs -L 1 aws servicediscovery delete-service --id`


