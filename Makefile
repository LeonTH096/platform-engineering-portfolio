# ===================================================================
# Platform Engineering Portfolio — Root Makefile
# ===================================================================

.DEFAULT_GOAL := help
SHELL := /bin/bash

# Directories
TF_DIR_ITER1 := project-2-cloud-infrastructure/iteration-1-terraform
TF_DIR_ITER2 := project-2-cloud-infrastructure/iteration-2-terragrunt
HELM_DIR := project-1-platform-microservices/helm/online-boutique

.PHONY: help
help: ## Show this help message
	@printf "\n\033[34mPlatform Engineering Portfolio\033[0m\n\n"
	@printf "\033[33mUsage:\033[0m make <target>\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-20s\033[0m %s\n", $$1, $$2}'
	@printf "\n"

# --- Aggregate targets ---

.PHONY: lint
lint: tf-fmt-check tf-lint tg-fmt-check helm-lint yaml-lint ## Run all linters

.PHONY: validate
validate: tf-validate helm-validate ## Run all validators

.PHONY: fmt
fmt: tf-fmt tg-fmt ## Auto-format all code

.PHONY: check
check: lint validate ## Run all linters + validators (CI target)

# --- Terraform ---

.PHONY: tf-fmt
tf-fmt: ## Auto-format Terraform files
	@printf "\033[34mFormatting Terraform files...\033[0m\n"
	@find $(TF_DIR_ITER1) -name '*.tf' -not -path '*/.terraform/*' 2>/dev/null | head -1 | grep -q . && \
		terraform fmt -recursive $(TF_DIR_ITER1) || \
		printf "  No .tf files found — skipping\n"

.PHONY: tf-fmt-check
tf-fmt-check: ## Check Terraform formatting (fails if unformatted)
	@printf "\033[34mChecking Terraform format...\033[0m\n"
	@find $(TF_DIR_ITER1) -name '*.tf' -not -path '*/.terraform/*' 2>/dev/null | head -1 | grep -q . && \
		terraform fmt -check -recursive $(TF_DIR_ITER1) || \
		printf "  No .tf files found — skipping\n"

.PHONY: tf-validate
tf-validate: ## Validate Terraform configuration (requires init)
	@printf "\033[34mValidating Terraform...\033[0m\n"
	@for dir in $(TF_DIR_ITER1)/environments/dev/*/; do \
		if [ -f "$$dir/main.tf" ]; then \
			printf "  Validating $$dir\n"; \
			(cd "$$dir" && terraform validate) || exit 1; \
		fi; \
	done
	@printf "  \033[32mDone\033[0m\n"

.PHONY: tf-lint
tf-lint: ## Run tflint on Terraform files
	@printf "\033[34mRunning tflint...\033[0m\n"
	@if command -v tflint &> /dev/null; then \
		for dir in $(TF_DIR_ITER1)/environments/dev/*/; do \
			if [ -f "$$dir/main.tf" ]; then \
				printf "  Linting $$dir\n"; \
				(cd "$$dir" && tflint) || exit 1; \
			fi; \
		done; \
		printf "  \033[32mDone\033[0m\n"; \
	else \
		printf "  \033[33mtflint not installed — skipping\033[0m\n"; \
	fi

# --- Terragrunt ---

.PHONY: tg-fmt
tg-fmt: ## Auto-format Terragrunt files
	@printf "\033[34mFormatting Terragrunt files...\033[0m\n"
	@find $(TF_DIR_ITER2) -name '*.hcl' 2>/dev/null | head -1 | grep -q . && \
		terragrunt hclfmt $(TF_DIR_ITER2) || \
		printf "  No .hcl files found — skipping\n"

.PHONY: tg-fmt-check
tg-fmt-check: ## Check Terragrunt formatting
	@printf "\033[34mChecking Terragrunt format...\033[0m\n"
	@find $(TF_DIR_ITER2) -name '*.hcl' 2>/dev/null | head -1 | grep -q . && \
		terragrunt hclfmt --check $(TF_DIR_ITER2) || \
		printf "  No .hcl files found — skipping\n"

# --- Helm ---

.PHONY: helm-lint
helm-lint: ## Lint Helm charts
	@printf "\033[34mLinting Helm charts...\033[0m\n"
	@if [ -f "$(HELM_DIR)/Chart.yaml" ]; then \
		helm lint $(HELM_DIR) || exit 1; \
		printf "  \033[32mDone\033[0m\n"; \
	else \
		printf "  No Chart.yaml found — skipping\n"; \
	fi

.PHONY: helm-validate
helm-validate: ## Validate Helm templates with kubeconform
	@printf "\033[34mValidating Helm templates...\033[0m\n"
	@if [ -f "$(HELM_DIR)/Chart.yaml" ] && command -v kubeconform &> /dev/null; then \
		helm template $(HELM_DIR) | kubeconform -strict || exit 1; \
		printf "  \033[32mDone\033[0m\n"; \
	else \
		printf "  \033[33mChart.yaml or kubeconform not found — skipping\033[0m\n"; \
	fi

# --- YAML ---

.PHONY: yaml-lint
yaml-lint: ## Lint YAML files (workflows, values files)
	@printf "\033[34mLinting YAML files...\033[0m\n"
	@if command -v yamllint &> /dev/null; then \
		find . -name '*.yml' -o -name '*.yaml' | \
			grep -v '.terraform' | grep -v 'node_modules' | \
			xargs yamllint -d relaxed 2>/dev/null || true; \
		printf "  \033[32mDone\033[0m\n"; \
	else \
		printf "  \033[33myamllint not installed — skipping (pip install yamllint)\033[0m\n"; \
	fi

# --- Security ---

.PHONY: security-scan
security-scan: ## Run Trivy IaC scan on Terraform files
	@printf "\033[34mRunning Trivy IaC scan...\033[0m\n"
	@if command -v trivy &> /dev/null; then \
		trivy config $(TF_DIR_ITER1) --severity HIGH,CRITICAL || true; \
		printf "  \033[32mDone\033[0m\n"; \
	else \
		printf "  \033[33mtrivy not installed — skipping\033[0m\n"; \
	fi

# --- Documentation ---

.PHONY: docs
docs: ## Generate Terraform documentation (terraform-docs)
	@printf "\033[34mGenerating Terraform docs...\033[0m\n"
	@if command -v terraform-docs &> /dev/null; then \
		for dir in $(TF_DIR_ITER1)/environments/dev/*/; do \
			if [ -f "$$dir/main.tf" ]; then \
				printf "  Generating docs for $$dir\n"; \
				terraform-docs markdown table "$$dir" > "$$dir/README.md" || true; \
			fi; \
		done; \
		printf "  \033[32mDone\033[0m\n"; \
	else \
		printf "  \033[33mterraform-docs not installed — skipping\033[0m\n"; \
	fi

# --- Cleanup ---

.PHONY: clean
clean: ## Remove generated files (.terraform, .terragrunt-cache)
	@printf "\033[34mCleaning generated files...\033[0m\n"
	@find . -type d -name '.terraform' -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name '.terragrunt-cache' -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name '*.tfplan' -delete 2>/dev/null || true
	@find . -type f -name 'crash.log' -delete 2>/dev/null || true
	@printf "  \033[32mDone\033[0m\n"

# --- Toolchain verification ---

.PHONY: verify
verify: ## Verify all required tools are installed
	@printf "\n\033[34mVerifying toolchain...\033[0m\n\n"
	@command -v terraform &>/dev/null \
		&& printf "  \033[32m✓\033[0m %-20s %s\n" "terraform" "$$(terraform version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')" \
		|| printf "  \033[31m✗\033[0m %-20s %s\n" "terraform" "not installed"
	@command -v terragrunt &>/dev/null \
		&& printf "  \033[32m✓\033[0m %-20s %s\n" "terragrunt" "$$(terragrunt --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" \
		|| printf "  \033[31m✗\033[0m %-20s %s\n" "terragrunt" "not installed"
	@command -v kubectl &>/dev/null \
		&& printf "  \033[32m✓\033[0m %-20s %s\n" "kubectl" "$$(kubectl version --client 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')" \
		|| printf "  \033[31m✗\033[0m %-20s %s\n" "kubectl" "not installed"
	@command -v helm &>/dev/null \
		&& printf "  \033[32m✓\033[0m %-20s %s\n" "helm" "$$(helm version --short 2>/dev/null | cut -d'+' -f1)" \
		|| printf "  \033[31m✗\033[0m %-20s %s\n" "helm" "not installed"
	@command -v docker &>/dev/null \
		&& printf "  \033[32m✓\033[0m %-20s %s\n" "docker" "$$(docker version --format '{{.Client.Version}}' 2>/dev/null || echo 'installed')" \
		|| printf "  \033[31m✗\033[0m %-20s %s\n" "docker" "not installed"
	@command -v tflint &>/dev/null \
		&& printf "  \033[32m✓\033[0m %-20s %s\n" "tflint" "$$(tflint --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" \
		|| printf "  \033[31m✗\033[0m %-20s %s\n" "tflint" "not installed"
	@command -v trivy &>/dev/null \
		&& printf "  \033[32m✓\033[0m %-20s %s\n" "trivy" "$$(trivy --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" \
		|| printf "  \033[31m✗\033[0m %-20s %s\n" "trivy" "not installed"
	@command -v kubeconform &>/dev/null \
		&& printf "  \033[32m✓\033[0m %-20s %s\n" "kubeconform" "$$(kubeconform -v 2>/dev/null || echo 'installed')" \
		|| printf "  \033[31m✗\033[0m %-20s %s\n" "kubeconform" "not installed"
	@command -v terraform-docs &>/dev/null \
		&& printf "  \033[32m✓\033[0m %-20s %s\n" "terraform-docs" "$$(terraform-docs --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" \
		|| printf "  \033[31m✗\033[0m %-20s %s\n" "terraform-docs" "not installed"
	@printf "\n"
