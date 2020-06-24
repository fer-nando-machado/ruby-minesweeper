.SILENT:
.DEFAULT_GOAL := help

.PHONY: help
help:
	$(info Available Commands:)
	$(info -> test                    runs tests)
	$(info -> run                     starts script)

.PHONY: test
test:
	irb *_test.rb

.PHONY: run
run:
	irb minesweeper.rb

# ignore unknown commands
%:
    @:
