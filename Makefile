EMACS ?= emacs
DEPS  := .deps

.PHONY: check compile test deps clean

check: compile test

deps: $(DEPS)

$(DEPS):
	$(EMACS) -Q --batch -l tests/install-deps.el

compile: $(DEPS)
	$(EMACS) -Q --batch -l tests/init-deps.el -l tests/compile.el

test: $(DEPS)
	$(EMACS) -Q --batch -l tests/init-deps.el -l tests/run-tests.el

clean:
	rm -rf $(DEPS)
