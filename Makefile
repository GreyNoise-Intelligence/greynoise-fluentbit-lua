-include env

CONTAINER := gn-fluentbit

.PHONY: clean
clean:
	@rm -rf output.log

.PHONY: build
build:
	docker build -t $(CONTAINER) .

.PHONY: shell
shell:
	docker run -it -v $(PWD):/app $(CONTAINER) /bin/bash

.PHONY: run-tail
run-tail: clean
	docker run -e FB_CONF_FILE=example_tail.conf -it -p 2020:2020 -v $(PWD):/app $(CONTAINER) ./run.sh

.PHONY: run
run: clean
	docker run -e FB_CONF_FILE=example_dummy.conf -it -p 2020:2020 -v $(PWD):/app $(CONTAINER) ./run.sh

# busted test.lua