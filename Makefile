-include env

CONTAINER := gn-fluentbit
WORKDIR := /app

.PHONY: clean
clean:
	@rm -rf output.log

.PHONY: build
build:
	docker build -t $(CONTAINER) .

.PHONY: shell
shell:
	docker run -it -v $(PWD):$(WORKDIR) $(CONTAINER) --shell

.PHONY: run-tail
run-tail: clean
	docker run -e FB_CONF_FILE=examples/tail.conf -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER)

.PHONY: run
run: clean
	docker run -e FB_CONF_FILE=examples/dummy.conf -it -p 2020:2020 -v $(PWD):$(WORKDIR) $(CONTAINER)

.PHONY: test
test:
	docker run -it -v $(PWD):$(WORKDIR) $(CONTAINER) --test
