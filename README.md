# ITL Identity Platform Documentation

This repository contains the documentation for the ITL Identity Platform, built with [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

## Quick Start

### Prerequisites

- Python 3.8 or higher (Python 3.11+ recommended)
- Git

### Setup

1. **Clone and setup**:
   ```bash
   cd ITL.identity.platform
   python setup.py
   ```

2. **Start development server**:
   ```bash
   python setup.py serve
   ```

3. **Open browser** to http://127.0.0.1:8000

### Manual Setup

If you prefer manual setup:

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Serve documentation
mkdocs serve
```

## Documentation Structure

```
docs/
├── index.md                    # Homepage
├── managed-identities-pim-architecture.md  # TOGAF Architecture
├── architecture/
│   └── overview.md            # Architecture overview
├── implementation/
│   ├── getting-started.md     # Implementation guide
│   └── components.md          # Component details
├── operations/
│   ├── deployment.md          # Deployment guide
│   └── monitoring.md          # Monitoring setup
└── security/
    ├── security-model.md      # Security architecture
    └── compliance.md          # Compliance framework
```

## Building and Deployment

### Local Development

```bash
# Start development server with live reload
mkdocs serve

# Build static site
mkdocs build
```

### PowerShell Build Script (Windows)

Use the provided PowerShell script for common tasks:

```powershell
# Show available commands
.\build.ps1 help

# Install dependencies
.\build.ps1 install

# Build and serve locally
.\build.ps1 serve

# Build documentation
.\build.ps1 build

# Test documentation
.\build.ps1 test

# Generate Kubernetes manifests (without validation)
.\build.ps1 helm-template

# Lint Helm chart
.\build.ps1 helm-lint

# Run all CI tests locally
.\build.ps1 ci-test
```

### Makefile (Linux/macOS)

```bash
# Show available targets
make help

# Install dependencies
make install

# Build and test
make all

# Generate manifests without validation
make helm-template

# Validate Kubernetes manifests
make helm-validate
```

### Production Build

```bash
# Build for production
mkdocs build --clean

# Deploy to GitHub Pages (if configured)
mkdocs gh-deploy
```

### CI/CD Pipeline

The GitHub Actions pipeline includes:

- **Validation**: Documentation build, Helm chart linting with `--validate=false` for Traefik CRDs
- **Security**: Docker image vulnerability scanning with Trivy (runs after successful image push)
- **Deployment**: Automated deployment to staging/production environments
- **Kubernetes**: Manifest generation with validation disabled for custom CRDs

**Note**: Kubernetes manifest validation is disabled (`--validate=false`) to avoid false positives with Traefik IngressRoute and Middleware CRDs which don't have public schemas available.

#### Security Scanning

The pipeline includes Trivy vulnerability scanning that:
- Only runs on successful image push (not on PRs)
- Requires proper GitHub Container Registry authentication
- Scans for CRITICAL and HIGH severity vulnerabilities only
- Uploads results to GitHub Security tab

## Troubleshooting

### Common Issues

#### "Unable to find specified image" Error
If you see Trivy failing with "unable to find the specified image", this usually means:
1. The image hasn't been pushed to the registry yet
2. The security scan job ran before the build job completed
3. Authentication to GitHub Container Registry failed

**Solution**: The pipeline has been updated to run security scanning in a separate job after the build completes.

#### "MANIFEST_UNKNOWN: manifest unknown" Error
This indicates the Docker image wasn't successfully pushed to the registry:
1. Check if the build job completed successfully
2. Verify GitHub Actions has `packages: write` permission
3. Ensure `GITHUB_TOKEN` has the necessary scopes

#### Kubernetes Validation Warnings
Warnings like "Failed initializing schema for IngressRoute" are expected and can be ignored:
- These occur because Traefik CRD schemas aren't available in public schema repositories
- The pipeline uses `--validate=false` to bypass these false positives
- Your manifests are still valid and will deploy correctly

### Local Development Issues

#### MkDocs Not Found
```bash
pip install -r requirements.txt
# or
.\build.ps1 install
```

#### Docker Build Fails
```bash
# Check Docker is running
docker version

# Clear Docker cache
docker system prune -a

# Rebuild from scratch
.\build.ps1 docker-build
```

## Configuration

The documentation is configured via `mkdocs.yml`:

- **Theme**: Material for MkDocs with dark/light mode support
- **Plugins**: Search, Mermaid diagrams
- **Extensions**: Code highlighting, admonitions, tabs, etc.
- **Navigation**: Organized by functional areas

### Dependencies

The project uses the latest stable versions:

- **MkDocs**: 1.6+ (documentation generator)
- **Material for MkDocs**: 9.5+ (theme with advanced features)
- **Mermaid Plugin**: 1.1+ (diagram support)
- **PyMdown Extensions**: 10.8+ (enhanced Markdown features)

All dependencies are automatically updated to their latest compatible versions.

## Branching Strategy and Workflow

This project follows a GitFlow-inspired branching strategy similar to the Keycloak theme workflow:

### Branch Structure

- **`main`**: Production-ready code. Triggers production deployment and creates releases.
- **`develop`**: Integration branch for features. Triggers staging deployment.
- **`feature/*`**: Feature development branches. Triggers validation workflows only.

### Workflow

1. **Feature Development**:
   ```bash
   # Create feature branch from develop
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   
   # Make your changes and push
   git add .
   git commit -m "feat: add your feature"
   git push origin feature/your-feature-name
   ```

2. **Feature Integration**:
   - Create PR from `feature/your-feature-name` to `develop`
   - Feature validation workflow runs automatically
   - After review and approval, merge to `develop`
   - No deployment (develop is for integration only)

3. **Release Preparation**:
   - Create PR from `develop` to `main`
   - After review and approval, merge to `main`
   - No deployment (main is for release preparation only)

4. **Production Deployment**:
   ```bash
   # Create version tag from main to trigger pipeline
   git checkout main
   git pull origin main
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
   
   Then **manually create the GitHub release**:
   1. Go to [GitHub Releases](https://github.com/ITlusions/ITL.identity.platform/releases)
   2. Click "Create a new release"
   3. Select tag: `v1.0.0`
   4. Add title: "Identity Platform Documentation v1.0.0"
   5. Write release notes
   6. Mark as pre-release if it's alpha/beta/rc/dev
   7. Publish release
   
   The pipeline will automatically upload artifacts to your release.

### CI/CD Behavior

| Branch/Tag Type | Build | Test | Deploy | Artifacts | Manual Release Required |
|-----------------|-------|------|--------|-----------|------------------------|
| `feature/*` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `develop` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `main` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `v*` tags | ✅ | ✅ | ✅ | ✅ | ✅ |
| PRs | ✅ | ✅ | ❌ | ❌ | ❌ |

**Note**: Version tags (`v*`) trigger deployment and artifact upload to **manually created** GitHub releases.

### Artifacts and Releases

- **Feature branches**: Validation only, no artifacts created
- **Develop branch**: Validation only, no artifacts created  
- **Main branch**: Validation only, no artifacts created
- **Version tags**: Artifacts uploaded to manually created releases:
  - Docker images with semantic version tags
  - Documentation site archive (`identity-docs-site-v*.tar.gz`)
  - Helm chart package (`identity-docs-v*.tgz`)
  - Production deployment to Kubernetes cluster

**Workflow**: Create tag → Create release manually → Pipeline uploads artifacts automatically

## Contributing

### Adding New Content

1. Create new Markdown files in the appropriate `docs/` subdirectory
2. Update navigation in `mkdocs.yml` if needed
3. Use relative links for internal references
4. Follow the existing style and structure

### Markdown Guidelines

- Use heading levels consistently (# for page title, ## for main sections)
- Include code examples with proper syntax highlighting
- Use admonitions for important notes, warnings, and tips
- Add diagrams using Mermaid when helpful

### Example Admonitions

```markdown
!!! note "Information"
    This is an informational note.

!!! warning "Important"
    This is a warning.

!!! tip "Pro Tip"
    This is a helpful tip.
```

### Mermaid Diagrams

```markdown
```mermaid
graph LR
    A[Start] --> B[Process]
    B --> C[End]
```
```

## Features

- 📖 **Rich Documentation**: Comprehensive architecture and implementation guides
- 🎨 **Material Design**: Modern, responsive theme with dark/light mode
- 🔍 **Full-text Search**: Built-in search functionality
- 📊 **Mermaid Diagrams**: Interactive architecture diagrams
- 📱 **Mobile Friendly**: Responsive design for all devices
- 🔗 **Cross-references**: Easy navigation between sections
- 💻 **Code Highlighting**: Syntax highlighting for multiple languages

## License

This documentation is part of the ITL Identity Platform project.

---

For questions or contributions, please refer to the main project repository.