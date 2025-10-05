# ITL Identity Platform Documentation

This repository contains the documentation for the ITL Identity Platform, built with [MkDocs](https://www.mkdocs.org/) and [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

## Quick Start

### Prerequisites

- Python 3.8 or higher
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

### Production Build

```bash
# Build for production
mkdocs build --clean

# Deploy to GitHub Pages (if configured)
mkdocs gh-deploy
```

## Configuration

The documentation is configured via `mkdocs.yml`:

- **Theme**: Material for MkDocs with dark/light mode support
- **Plugins**: Search, Mermaid diagrams
- **Extensions**: Code highlighting, admonitions, tabs, etc.
- **Navigation**: Organized by functional areas

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