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

.PHONY: run
run: clean
	docker run -it -p 2020:2020 -v $(PWD):/app $(CONTAINER) ./run.sh

# busted test.lua