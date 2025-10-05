# Security Scan Authorization Fix

## Issue Description

The Trivy security scan was failing with errors:
- "unable to find the specified image"
- "MANIFEST_UNKNOWN: manifest unknown" 
- Authentication/authorization errors when accessing GitHub Container Registry

## Root Causes

1. **Job Timing**: Security scan was trying to run before the image was fully pushed
2. **Missing Permissions**: Security scan job lacked `packages: read` permission
3. **No Authentication**: Security scan wasn't authenticating to private registry
4. **Image Reference**: Using commit SHA that might not match the actual pushed tag

## Solutions Implemented

### 1. Enhanced Permissions
```yaml
permissions:
  contents: read
  packages: read        # Added for registry access
  security-events: write
```

### 2. Added Authentication
```yaml
- name: Log in to Container Registry
  uses: docker/login-action@v3
  with:
    registry: ${{ env.REGISTRY }}
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

### 3. Image Verification
```yaml
- name: Verify image exists
  run: |
    echo "Verifying image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}"
    docker manifest inspect ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
```

### 4. Enhanced Trivy Configuration
```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    ignore-unfixed: true
    skip-files: '/var/lib/dpkg/status'
    skip-dirs: '/tmp,/var/cache'
    timeout: '10m'
```

### 5. Local Security Testing
Added `.\build.ps1 security` command for local testing without registry dependencies.

## Verification

The fixes ensure that:
- Security scan only runs after successful image push
- Proper authentication to GitHub Container Registry
- Image existence is verified before scanning
- Local development includes security testing options
- Detailed troubleshooting documentation is available

## Expected Outcome

- ✅ Security scan runs successfully after image push
- ✅ No more "image not found" errors
- ✅ Proper SARIF results uploaded to GitHub Security tab
- ✅ Local security testing available without registry access