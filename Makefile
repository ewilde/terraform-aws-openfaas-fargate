alertmanager_version := "v0.15.1"
prometheus_version := "v2.3.1"
nats_streaming_version := "0.11.2"
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

docker-publish: docker-build
	@docker push ewilde/alertmanager:${alertmanager_version}
	@docker push ewilde/prometheus:${prometheus_version}
	@docker push ewilde/nats-streaming:${nats_streaming_version}

docker-build:
	@docker build ./docker/alertmanager/ -t ewilde/alertmanager:${alertmanager_version}
	@docker build ./docker/prometheus/ -t ewilde/prometheus:${prometheus_version}
	@docker build --build-arg NATS_VERSION=${nats_streaming_version} ./docker/nats-streaming/ -t ewilde/nats-streaming:${nats_streaming_version}
uninstall: destroy

.PHONY: install uninstall keys init apply destroy
