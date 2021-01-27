-include env

CONTAINER := gn-fluentbit
WORKDIR := /app

.docker-build: build
	@touch .docker-build

.PHONY: build
build:
	docker build -t $(CONTAINER) .

.PHONY: clean
clean:
	@rm -rf .docker-build output/*

.PHONY: shell
shell: .docker-build
	docker run -it --entrypoint /bin/bash -v $(PWD):$(WORKDIR) $(CONTAINER)

.PHONY: run-tail
run-tail: clean .docker-build
	docker run --env-file .env -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER) -c conf/tail.conf

.PHONY: run-rewrite
run-rewrite: clean .docker-build
	docker run --env-file .env -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER) -c conf/rewrite.conf

.PHONY: run
run: clean .docker-build
	docker run --env-file .env -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER) -c conf/dummy.conf

.PHONY: test
test: clean .docker-build
	docker run --env-file .env_example --entrypoint /usr/local/bin/busted -v $(PWD):$(WORKDIR) $(CONTAINER) -C ./greynoise spec/test.lua

.PHONY: lint
lint:
	luacheck -d greynoise/**/*.lua

.PHONY: format
format:
	lua-format -i -c .lua-format greynoise/**/*.lua

.PHONY: stats
stats:
	./scripts/stats.sh
