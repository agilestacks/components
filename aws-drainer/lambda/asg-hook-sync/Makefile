function ?= "asg-sync-r53-dev-kubernetes-delivery"

aws  ?= aws
venv ?= .venv

PACKAGE := lambda.zip

default: clear init install package

clear:
	rm -rf $(venv) $(PACKAGE)
.PHONY: deploy

init:
	rm -rf $(venv)
	virtualenv $(venv) || virtualenv -p $$(which python3) $(venv)

deploy: install package
	$(aws) lambda update-function-code --function-name="$(function)" --zip-file=fileb://$(PACKAGE) --publish
.PHONY: deploy

install: init
	. $(venv)/bin/activate && pip install -r requirements.txt -t lib --upgrade

test:
	python3 test_main.py

$(PACKAGE):
	zip -qr9 $@ . -x@.zipignore

package: $(PACKAGE)

