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
	@rm -rf examples/output.log .docker-build

.PHONY: shell
shell: .docker-build
	docker run -it -v $(PWD):$(WORKDIR) $(CONTAINER) --shell

.PHONY: run-tail
run-tail: clean .docker-build
	docker run -e FB_CONF_FILE=examples/tail.conf -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER)

.PHONY: run
run: clean .docker-build
	docker run -e FB_CONF_FILE=examples/dummy.conf -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER)

.PHONY: test
test: .docker-build
	docker run --env-file .env_example -v $(PWD):$(WORKDIR) $(CONTAINER) --test
