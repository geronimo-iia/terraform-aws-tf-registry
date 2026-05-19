
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

checkov:
	checkov -d . --quiet --framework terraform


.PHONY: prep
prep:
	@terraform init -backend=false

.PHONY: lint
lint: prep ## Check for possible errors, best practices, etc in current directory!
	@terraform fmt -write=true -recursive
	@tflint

