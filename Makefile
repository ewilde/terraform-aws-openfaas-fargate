default: install

install: init apply

init:
	@terraform init

apply:
	@terraform apply

destroy:
	@terraform destroy

keys:
	@ssh-keygen -t rsa -f ./keys/openfaas
	@chmod 400 ./keys/openfaas
	@chmod 400 ./keys/openfaas.pub

uninstall: destroy

.PHONY: install uninstall keys init apply destroy
