-include env

CONTAINER := gn-fluentbit
WORKDIR := /app

.docker-build: build
	@touch .docker-build

.PHONY: build
build:
	docker build -t $(CONTAINER) .

.PHONY: push
push: .docker-build
	docker login -u $(USERNAME_PASSWORD) -p $(DOCKERHUB_PASSWORD)
	docker tag $(CONTAINER) greynoise/greynoise-fluentbit-lua:$(TAG)
	docker push greynoise/greynoise-fluentbit-lua:$(TAG)

.PHONY: clean
clean:
	@rm -rf .docker-build output/*

.PHONY: shell
shell: .docker-build
	docker run -it --entrypoint /bin/bash -v $(PWD):$(WORKDIR) $(CONTAINER)

.PHONY: run-tail
run-tail: clean .docker-build
	docker run --env GREYNOISE_IP_FIELD=host --env-file .env -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER) -c /app/conf/tail.conf

.PHONY: run-rewrite
run-rewrite: clean .docker-build
	docker run --env GREYNOISE_IP_FIELD=host --env-file .env -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER) -c /app/conf/rewrite.conf

.PHONY: run-vpc
run-vpc: clean .docker-build
	docker run --env GREYNOISE_IP_FIELD=srcaddr --env-file .env -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER) -c /app/conf/vpc.conf

.PHONY: run
run: clean .docker-build
	docker run --env-file .env -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER) -c /app/conf/dummy.conf

.PHONY: test
test: clean .docker-build
	docker run --env-file .env_example --entrypoint /usr/local/bin/busted -v $(PWD):$(WORKDIR) $(CONTAINER) -C /opt/greynoise spec/test.lua

.PHONY: lint
lint:
	luacheck -d greynoise/**/*.lua

.PHONY: format
format:
	lua-format -i -c .lua-format greynoise/**/*.lua

.PHONY: stats
stats:
	./scripts/stats.sh
