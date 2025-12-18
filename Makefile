.PHONY: help bootstrap validate cleanup apply-network apply-database test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Bootstrap Crossplane and prerequisites
	@./scripts/bootstrap.sh

validate: ## Validate Crossplane installation
	@./scripts/validate.sh

cleanup: ## Clean up all resources
	@./scripts/cleanup.sh

apply-network: ## Create network infrastructure
	kubectl apply -f examples/aws-network.yaml

apply-database: ## Create database and cache
	kubectl apply -f examples/chatapp-claim.yaml

test: ## Run validation tests
	@echo "Running tests..."
	kubectl apply --dry-run=client -f apis/
	kubectl apply --dry-run=client -f examples/
	@echo "✅ Tests passed"
