# PowerShell build script for ITL Identity Platform Documentation
# Usage: .\build.ps1 [command]

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

function Show-Help {
    Write-Host "ITL Identity Platform Documentation Build Script" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage: .\build.ps1 [command]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Cyan
    Write-Host "  help              Show this help message"
    Write-Host "  install           Install Python dependencies"
    Write-Host "  build             Build documentation"
    Write-Host "  serve             Serve documentation locally"
    Write-Host "  clean             Clean build artifacts"
    Write-Host "  docker-build      Build Docker image"
    Write-Host "  docker-run        Run Docker container"
    Write-Host "  docker-stop       Stop Docker container"
    Write-Host "  helm-lint         Lint Helm chart"
    Write-Host "  helm-template     Generate Kubernetes manifests (without validation)"
    Write-Host "  helm-validate     Validate Kubernetes manifests"
    Write-Host "  test              Test documentation build"
    Write-Host "  security          Run security scan on local Docker image"
    Write-Host "  ci-test           Run CI tests locally"
    Write-Host "  all               Run all build steps"
}

function Install-Dependencies {
    Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
    python -m pip install --upgrade pip
    pip install -r requirements.txt
}

function Build-Documentation {
    Write-Host "Building documentation..." -ForegroundColor Yellow
    mkdocs build --clean --strict
}

function Serve-Documentation {
    Write-Host "Serving documentation locally..." -ForegroundColor Yellow
    mkdocs serve
}

function Clean-Artifacts {
    Write-Host "Cleaning build artifacts..." -ForegroundColor Yellow
    if (Test-Path "site") { Remove-Item -Recurse -Force "site" }
    if (Test-Path "manifests*.yaml") { Remove-Item "manifests*.yaml" }
}

function Build-Docker {
    Write-Host "Building Docker image..." -ForegroundColor Yellow
    docker build -t ghcr.io/itlusions/identity-docs:latest .
}

function Run-Docker {
    Write-Host "Running Docker container..." -ForegroundColor Yellow
    docker run --rm -d -p 8080:80 --name identity-docs ghcr.io/itlusions/identity-docs:latest
    Write-Host "Documentation available at http://localhost:8080" -ForegroundColor Green
}

function Stop-Docker {
    Write-Host "Stopping Docker container..." -ForegroundColor Yellow
    docker stop identity-docs 2>$null
}

function Lint-Helm {
    Write-Host "Linting Helm chart..." -ForegroundColor Yellow
    helm lint charts/identity-docs --strict
}

function Template-Helm {
    Write-Host "Generating Kubernetes manifests (without validation)..." -ForegroundColor Yellow
    helm template identity-docs charts/identity-docs --validate=false > manifests.yaml
    Write-Host "Manifests generated: manifests.yaml" -ForegroundColor Green
}

function Validate-Helm {
    Write-Host "Validating Kubernetes manifests..." -ForegroundColor Yellow
    helm template identity-docs charts/identity-docs --validate=false > manifests-test.yaml
    
    # Check if kubeval is available
    $kubeval = Get-Command kubeval -ErrorAction SilentlyContinue
    if ($kubeval) {
        kubeval manifests-test.yaml --ignore-missing-schemas --skip-kinds IngressRoute,Middleware,ServiceMonitor
    } else {
        Write-Host "kubeval not found. Skipping Kubernetes validation." -ForegroundColor Yellow
        Write-Host "To install kubeval: https://github.com/instrumenta/kubeval" -ForegroundColor Cyan
    }
}

function Test-Build {
    Write-Host "Testing documentation build..." -ForegroundColor Yellow
    mkdocs build --strict
    Write-Host "Documentation built successfully" -ForegroundColor Green
}

function Test-Security {
    Write-Host "Running security scan on local Docker image..." -ForegroundColor Yellow
    
    # Check if trivy is available
    $trivy = Get-Command trivy -ErrorAction SilentlyContinue
    if ($trivy) {
        # Scan the local image (if it exists)
        $imageName = "ghcr.io/itlusions/identity-docs:latest"
        $localImage = docker images --format "table {{.Repository}}:{{.Tag}}" | Select-String $imageName
        
        if ($localImage) {
            Write-Host "Scanning image: $imageName" -ForegroundColor Cyan
            trivy image --severity HIGH,CRITICAL --ignore-unfixed $imageName
        } else {
            Write-Host "Local image not found. Build the image first with: .\build.ps1 docker-build" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Trivy not found. Install from: https://github.com/aquasecurity/trivy" -ForegroundColor Yellow
        Write-Host "Or use the CI pipeline for security scanning." -ForegroundColor Cyan
    }
}

function Run-CiTest {
    Write-Host "Running CI tests locally..." -ForegroundColor Yellow
    Test-Build
    Lint-Helm
    Validate-Helm
}

function Run-All {
    Write-Host "Running all build steps..." -ForegroundColor Yellow
    Clean-Artifacts
    Install-Dependencies
    Build-Documentation
    Lint-Helm
    Template-Helm
}

# Main command dispatcher
switch ($Command.ToLower()) {
    "help" { Show-Help }
    "install" { Install-Dependencies }
    "build" { Build-Documentation }
    "serve" { Serve-Documentation }
    "clean" { Clean-Artifacts }
    "docker-build" { Build-Docker }
    "docker-run" { Run-Docker }
    "docker-stop" { Stop-Docker }
    "helm-lint" { Lint-Helm }
    "helm-template" { Template-Helm }
    "helm-validate" { Validate-Helm }
    "test" { Test-Build }
    "security" { Test-Security }
    "ci-test" { Run-CiTest }
    "all" { Run-All }
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Show-Help
        exit 1
    }
}