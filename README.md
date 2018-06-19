# Overview
![diagram of the openfaas on fargate architecture](./docs/architecture.png "Openfaas for fargate overview")

# Prerequisites
## Terraform variables
|Name|Description|
|----|-----------|
|aws_region|The aws region to create the openfaas ecs cluster in|
|debug| `1` to create an ec2 bastion in the external subnet and a test instance in the internal subnet|
|developer_ip| your ip address, used to whitelist incoming ssh to bastion|

1. Configure your terraform.tfvars i.e.
```
cat > ./terraform.tfvars <<EOF
aws_region   = "eu-west-1"
debug        = "1"
developer_ip = "217.46.68.185"
EOF
```
1. (Optional) Key pair for debug instances. 
```
cd keys
ssh-keygen -t rsa
```
