
.PHONY: init-tools
init-tools:
	@echo Installing ASDF plugins
	@asdf plugin add terraform
	@asdf plugin add terraform-docs
	@asdf plugin add tflint
	@asdf plugin add terragrunt
	@asdf plugin add tfsec
	@asdf plugin add checkov
	@asdf install


.PHONY: doc
doc:
	@terraform-docs markdown table --output-file README.md --output-mode inject . 

.PHONY: tfsec
tfsec:
	tfsec .

checkov:
	checkov -d . --quiet --framework terraform --config-file checkov.yaml
