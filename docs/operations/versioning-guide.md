# 🏷️ Development Build Versioning Guide

This guide explains how to create development builds with proper semantic versioning.

## 📋 **Version Types**

### **Stable Releases**
- **Format**: `vX.Y.Z`
- **Example**: `v1.0.0`, `v2.1.3`
- **When**: Production-ready releases
- **Source**: Usually from `main` branch
- **Deployment**: Full production deployment

### **Pre-release Versions**

#### **Alpha Builds** 🔬
- **Format**: `vX.Y.Z-alpha.N`
- **Example**: `v1.2.0-alpha.1`, `v1.2.0-alpha.2`
- **When**: Very early development, major features in progress
- **Source**: Usually from `develop` or feature branches
- **Deployment**: Development/testing environments only

#### **Beta Builds** 🧪
- **Format**: `vX.Y.Z-beta.N`
- **Example**: `v1.2.0-beta.1`, `v1.2.0-beta.2`
- **When**: Feature complete, ready for broader testing
- **Source**: Usually from `develop` branch
- **Deployment**: Staging/UAT environments

#### **Release Candidates** 🎯
- **Format**: `vX.Y.Z-rc.N`
- **Example**: `v1.2.0-rc.1`, `v1.2.0-rc.2`
- **When**: Final testing before stable release
- **Source**: Usually from `main` branch
- **Deployment**: Pre-production environments

#### **Development Snapshots** 📸
- **Format**: `vX.Y.Z-dev.N`
- **Example**: `v1.2.0-dev.1`, `v1.2.0-dev.2`
- **When**: Regular development snapshots
- **Source**: Any branch
- **Deployment**: Development environments

## 🚀 **Quick Usage Examples**

### **Create Development Builds**

```powershell
# Early development build
.\release.ps1 -Version v1.2.0-alpha.1 -Message "Add new authentication features"

# Feature complete, ready for testing
.\release.ps1 -Version v1.2.0-beta.1 -Message "Feature complete - OIDC integration"

# Release candidate
.\release.ps1 -Version v1.2.0-rc.1 -Message "Final testing before release"

# Development snapshot
.\release.ps1 -Version v1.2.0-dev.1 -FromBranch feature/new-ui
```

### **Create Stable Releases**

```powershell
# Major release
.\release.ps1 -Version v2.0.0 -Message "Major release with breaking changes"

# Minor release (new features)
.\release.ps1 -Version v1.3.0 -Message "Add new monitoring features"

# Patch release (bug fixes)
.\release.ps1 -Version v1.2.1 -Message "Fix authentication bug"
```

## 📊 **Version Progression Example**

Here's how versions typically progress during development:

```
v1.1.0              # Previous stable release
├── v1.2.0-alpha.1  # Early development
├── v1.2.0-alpha.2  # More features added
├── v1.2.0-beta.1   # Feature complete
├── v1.2.0-beta.2   # Bug fixes
├── v1.2.0-rc.1     # Release candidate
├── v1.2.0-rc.2     # Final fixes
└── v1.2.0          # Stable release
```

## 🔄 **Deployment Strategy**

| Version Type | Environment | Auto Deploy | Manual Review |
|--------------|-------------|-------------|---------------|
| `alpha.*` | Development | ✅ | ❌ |
| `beta.*` | Staging | ✅ | ❌ |
| `rc.*` | Pre-production | ✅ | ⚠️ Recommended |
| `dev.*` | Development | ✅ | ❌ |
| Stable | Production | ✅ | ✅ Required |

## 📝 **Best Practices**

### **Numbering**
- Start alpha/beta/rc numbering from 1 (not 0)
- Increment sequentially: `alpha.1`, `alpha.2`, `alpha.3`
- Reset numbering for each type: `alpha.1` → `beta.1` → `rc.1`

### **Timing**
- **Alpha**: Internal development, breaking changes expected
- **Beta**: External testing, feature freeze
- **RC**: Production candidate, bug fixes only
- **Stable**: Production ready, well tested

### **Branch Strategy**
- **Alpha/Dev**: From `develop` or feature branches
- **Beta**: From `develop` branch (stable features)
- **RC**: From `main` branch (production ready)
- **Stable**: From `main` branch (fully tested)

## 🛠️ **Advanced Options**

### **With Build Metadata**
```powershell
# Add build number
.\release.ps1 -Version v1.2.0-alpha.1 -BuildMetadata "build.123"
# Result: v1.2.0-alpha.1+build.123

# Add commit hash
.\release.ps1 -Version v1.2.0-beta.1 -BuildMetadata "sha.abc1234"
# Result: v1.2.0-beta.1+sha.abc1234

# Add date
.\release.ps1 -Version v1.2.0-dev.1 -BuildMetadata "20231006"
# Result: v1.2.0-dev.1+20231006
```

### **Custom Source Branch**
```powershell
# Create beta from specific branch
.\release.ps1 -Version v1.2.0-beta.1 -FromBranch feature/new-auth

# Create hotfix release
.\release.ps1 -Version v1.1.1 -FromBranch hotfix/security-fix
```

## 🎯 **When to Use Each Type**

| Scenario | Version Type | Example |
|----------|--------------|---------|
| Weekly development builds | `dev.*` | `v1.2.0-dev.1` |
| New feature in progress | `alpha.*` | `v1.2.0-alpha.1` |
| Feature ready for QA | `beta.*` | `v1.2.0-beta.1` |
| Ready for production testing | `rc.*` | `v1.2.0-rc.1` |
| Production deployment | Stable | `v1.2.0` |
| Bug fix | Patch | `v1.2.1` |
| Security hotfix | Patch | `v1.2.2` |

This versioning strategy ensures clear communication about the stability and readiness of each build! 🚀

## 🔧 **Troubleshooting**

### **Common Issues**

#### **Invalid Docker Tag Format**
**Error**: `invalid tag "ghcr.io/repo::-sha123": invalid reference format`

**Cause**: Special characters in branch names or tag generation
**Fix**: Our pipeline automatically handles this by using safe tag formats

#### **Tag Already Exists**
**Error**: `Tag 'v1.0.0' already exists`

**Solutions**:
```powershell
# Check existing tags
git tag -l "v1.0.*"

# Delete local tag (if needed)
git tag -d v1.0.0

# Delete remote tag (careful!)
git push origin --delete v1.0.0

# Create new tag with incremented version
.\release.ps1 -Version v1.0.1
```

#### **Permission Denied**
**Error**: `Permission denied (publickey)`

**Fix**: Ensure you have push permissions to the repository
```powershell
# Check remote URL
git remote -v

# Test SSH connection
ssh -T git@github.com
```

### **Docker Tag Examples**
Our pipeline generates these tag formats:

| Version Input | Generated Docker Tags |
|---------------|----------------------|
| `v1.0.0` | `v1.0.0`, `1.0.0`, `1.0`, `1`, `latest`, `sha-abc123` |
| `v1.2.0-alpha.1` | `v1.2.0-alpha.1`, `1.2.0-alpha.1`, `sha-abc123` |
| `feature/test` | `feature-test`, `sha-abc123` |
| `main` | `main`, `latest`, `sha-abc123` |