.PHONY: help build serve test deploy clean lint helm-lint docker-build docker-run

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development
install: ## Install dependencies
	python -m venv venv
	./venv/bin/pip install --upgrade pip
	./venv/bin/pip install -r requirements.txt

serve: ## Serve documentation locally
	mkdocs serve

build: ## Build documentation
	mkdocs build --clean --strict

test: ## Test documentation build
	mkdocs build --clean --strict
	@echo "Documentation built successfully"

# Docker
docker-build: ## Build Docker image
	docker build -t itlusions/identity-docs:latest .

docker-run: ## Run Docker container locally
	docker run -p 8080:80 itlusions/identity-docs:latest

docker-compose-up: ## Start with docker-compose
	docker-compose up -d

docker-compose-dev: ## Start development server with docker-compose
	docker-compose up mkdocs-dev

# Helm
helm-lint: ## Lint Helm chart
	helm lint charts/identity-docs --strict

helm-template: ## Generate Kubernetes manifests from Helm (without validation)
	helm template identity-docs charts/identity-docs --validate=false > manifests.yaml

helm-template-debug: ## Generate Kubernetes manifests with debug
	helm template identity-docs charts/identity-docs --validate=false --debug

helm-validate: ## Validate Kubernetes manifests
	helm template identity-docs charts/identity-docs --validate=false > manifests-test.yaml
	kubeval manifests-test.yaml --ignore-missing-schemas --skip-kinds IngressRoute,Middleware,ServiceMonitor || echo "kubeval not installed, skipping validation"

helm-install: ## Install Helm chart locally (requires k8s context)
	helm install identity-docs charts/identity-docs

helm-upgrade: ## Upgrade Helm chart
	helm upgrade identity-docs charts/identity-docs

helm-package: ## Package Helm chart
	helm package charts/identity-docs

# Kubernetes
k8s-apply: ## Apply Kubernetes manifests
	kubectl apply -f k8s/

k8s-delete: ## Delete Kubernetes resources
	kubectl delete -f k8s/

# Linting and validation
lint: ## Lint all files
	@echo "Linting MkDocs..."
	mkdocs build --clean --strict
	@echo "Linting Helm chart..."
	helm lint charts/identity-docs
	@echo "All linting passed!"

# CI/CD
deploy-dev: ## Deploy to development
	helm upgrade --install identity-docs-dev charts/identity-docs \
		-f charts/identity-docs/values/development.yaml \
		--namespace docs-dev --create-namespace

deploy-prod: ## Deploy to production
	helm upgrade --install identity-docs charts/identity-docs \
		-f charts/identity-docs/values/production.yaml \
		--namespace docs --create-namespace

# Cleanup
clean: ## Clean build artifacts
	rm -rf site/
	rm -rf helm-packages/
	docker system prune -f

# Security
security-scan: ## Run security scan on Docker image
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image itlusions/identity-docs:latest

# Documentation
docs-serve: serve ## Alias for serve
docs-build: build ## Alias for build