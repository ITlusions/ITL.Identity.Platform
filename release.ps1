#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create a release tag from development work
    
.DESCRIPTION
    This script helps create proper version tags that trigger deployments.
    It supports both stable releases and pre-release versions (alpha, beta, rc, dev).
    
.PARAMETER Version
    The version to create (e.g., v1.0.0, v1.2.0-alpha.1, v1.2.0-beta.1, v1.2.0-rc.1)
    
.PARAMETER FromBranch
    The source branch to create the release from (default: develop for pre-release, main for stable)
    
.PARAMETER Message
    Custom release message (optional)
    
.PARAMETER BuildMetadata
    Optional build metadata (e.g., build.123, sha.abc1234)
    
.EXAMPLE
    .\release.ps1 -Version v1.0.0 -Message "Initial stable release"
    
.EXAMPLE
    .\release.ps1 -Version v1.2.0-alpha.1 -Message "Early development build"
    
.EXAMPLE
    .\release.ps1 -Version v1.2.0-beta.1 -FromBranch develop -BuildMetadata "build.123"
    
.EXAMPLE
    .\release.ps1 -Version v1.2.0-rc.1 -Message "Release candidate"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$FromBranch = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Message = "",
    
    [Parameter(Mandatory=$false)]
    [string]$BuildMetadata = ""
)

function Write-Step {
    param([string]$Message)
    Write-Host "🔄 $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Validate version format and determine release type
$isPreRelease = $false
$releaseType = "stable"

if ($Version -match '^v\d+\.\d+\.\d+$') {
    # Stable release (v1.0.0)
    $releaseType = "stable"
    $isPreRelease = $false
} elseif ($Version -match '^v\d+\.\d+\.\d+-(alpha|beta|rc|dev)\.\d+$') {
    # Pre-release (v1.0.0-alpha.1, v1.0.0-beta.1, etc.)
    $releaseType = $Matches[1]
    $isPreRelease = $true
} else {
    Write-Error "Version must be in format:"
    Write-Host "  Stable:     vX.Y.Z (e.g., v1.0.0)" -ForegroundColor Gray
    Write-Host "  Alpha:      vX.Y.Z-alpha.N (e.g., v1.2.0-alpha.1)" -ForegroundColor Gray
    Write-Host "  Beta:       vX.Y.Z-beta.N (e.g., v1.2.0-beta.1)" -ForegroundColor Gray
    Write-Host "  RC:         vX.Y.Z-rc.N (e.g., v1.2.0-rc.1)" -ForegroundColor Gray
    Write-Host "  Dev:        vX.Y.Z-dev.N (e.g., v1.2.0-dev.1)" -ForegroundColor Gray
    exit 1
}

# Set default source branch based on release type
if ([string]::IsNullOrEmpty($FromBranch)) {
    if ($isPreRelease) {
        $FromBranch = "develop"
    } else {
        $FromBranch = "main"
    }
}

# Add build metadata if provided
$finalVersion = $Version
if (-not [string]::IsNullOrEmpty($BuildMetadata)) {
    $finalVersion = "$Version+$BuildMetadata"
}

# Set default message if not provided
if ([string]::IsNullOrEmpty($Message)) {
    switch ($releaseType) {
        "alpha" { $Message = "Alpha release $Version - Early development build" }
        "beta" { $Message = "Beta release $Version - Feature complete, testing phase" }
        "rc" { $Message = "Release candidate $Version - Pre-production testing" }
        "dev" { $Message = "Development build $Version - Snapshot release" }
        "stable" { $Message = "Stable release $Version" }
    }
}

Write-Host "🚀 Creating $releaseType release $finalVersion from branch '$FromBranch'" -ForegroundColor Yellow
if ($isPreRelease) {
    Write-Host "   📦 Pre-release build - suitable for testing" -ForegroundColor Magenta
} else {
    Write-Host "   🎯 Stable release - production ready" -ForegroundColor Green
}
Write-Host ""

try {
    # Check if we're in a git repository
    Write-Step "Checking git repository..."
    git status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Not in a git repository"
    }
    Write-Success "Git repository detected"

    # Check for uncommitted changes
    Write-Step "Checking for uncommitted changes..."
    $status = git status --porcelain
    if ($status) {
        Write-Error "You have uncommitted changes. Please commit or stash them first:"
        git status --short
        exit 1
    }
    Write-Success "Working directory is clean"

    # Fetch latest changes
    Write-Step "Fetching latest changes..."
    git fetch origin
    Write-Success "Fetched latest changes"

    # Check if source branch exists
    Write-Step "Checking source branch '$FromBranch'..."
    $branchExists = git branch -r | Select-String "origin/$FromBranch"
    if (-not $branchExists) {
        throw "Branch 'origin/$FromBranch' does not exist"
    }
    Write-Success "Source branch '$FromBranch' exists"

    # Check if tag already exists
    Write-Step "Checking if tag '$Version' already exists..."
    $tagExists = git tag -l $Version
    if ($tagExists) {
        throw "Tag '$Version' already exists"
    }
    Write-Success "Tag '$Version' is available"

    # Switch to and update source branch
    Write-Step "Switching to branch '$FromBranch'..."
    git checkout $FromBranch
    git pull origin $FromBranch
    Write-Success "Updated branch '$FromBranch'"

    # Handle merge strategy based on release type
    if ($isPreRelease) {
        # For pre-releases, create tag directly from source branch
        Write-Step "Creating pre-release tag '$finalVersion' from '$FromBranch'..."
        git tag -a $Version -m "$Message"
        git push origin $Version
        Write-Success "Created and pushed pre-release tag '$Version'"
    } else {
        # For stable releases, merge to main first
        Write-Step "Merging '$FromBranch' into main for stable release..."
        git checkout main
        git pull origin main
        git merge $FromBranch --no-ff -m "Merge $FromBranch for release $Version"
        git push origin main
        Write-Success "Merged into main and pushed"

        # Create stable release tag
        Write-Step "Creating stable release tag '$finalVersion'..."
        git tag -a $Version -m "$Message"
        git push origin $Version
        Write-Success "Created and pushed stable release tag '$Version'"
    }

    Write-Host ""
    Write-Host "🎉 $releaseType release $Version created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 What happens next:" -ForegroundColor Yellow
    Write-Host "   • Create the GitHub release manually with:" -ForegroundColor White
    Write-Host "     - Tag: $Version" -ForegroundColor Gray
    Write-Host "     - Title: Identity Platform Documentation $Version" -ForegroundColor Gray
    Write-Host "     - Description: Your release notes" -ForegroundColor Gray
    if ($isPreRelease) {
        Write-Host "     - Mark as pre-release: ✅" -ForegroundColor Gray
    } else {
        Write-Host "     - Mark as pre-release: ❌" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "   • GitHub Actions will automatically:" -ForegroundColor White
    Write-Host "     - Build Docker image with tag: $Version" -ForegroundColor Gray
    Write-Host "     - Run security scans" -ForegroundColor Gray
    Write-Host "     - Upload artifacts to your release:" -ForegroundColor Gray
    Write-Host "       * Documentation site archive" -ForegroundColor Gray
    Write-Host "       * Helm chart package" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔗 Monitor progress at:" -ForegroundColor Yellow
    Write-Host "   https://github.com/ITlusions/ITL.identity.platform/actions" -ForegroundColor Blue
    Write-Host ""
    Write-Host "📦 Docker image will be available at:" -ForegroundColor Yellow
    Write-Host "   ghcr.io/itlusions/identity-docs:$Version" -ForegroundColor Blue
    Write-Host ""
    Write-Host "📝 Manual Steps:" -ForegroundColor Yellow
    Write-Host "   1. Go to: https://github.com/ITlusions/ITL.identity.platform/releases" -ForegroundColor Blue
    Write-Host "   2. Click 'Create a new release'" -ForegroundColor Gray
    Write-Host "   3. Select tag: $Version" -ForegroundColor Gray
    Write-Host "   4. Add release notes and publish" -ForegroundColor Gray
    Write-Host "   5. Artifacts will be uploaded automatically" -ForegroundColor Gray

} catch {
    Write-Error "Failed to create release: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   • Ensure you have push permissions to the repository" -ForegroundColor Gray
    Write-Host "   • Check that all changes are committed" -ForegroundColor Gray
    Write-Host "   • Verify the source branch exists and is up to date" -ForegroundColor Gray
    exit 1
}