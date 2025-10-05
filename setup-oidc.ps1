#!/usr/bin/env pwsh
# Setup script for OIDC authentication
# File: setup-oidc.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$KeycloakUrl = "https://sso.yourdomain.com",
    
    [Parameter(Mandatory=$false)]
    [string]$Realm = "itl-platform",
    
    [Parameter(Mandatory=$false)]
    [string]$ClientId = "itl-docs-client",
    
    [Parameter(Mandatory=$false)]
    [string]$DocsUrl = "http://localhost:8080"
)

Write-Host "🔐 Setting up OIDC Authentication for ITL Identity Platform Documentation" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Function to generate random string
function New-RandomString {
    param([int]$Length = 32)
    return -join ((1..$Length) | ForEach-Object { Get-Random -InputObject ([char[]](65..90 + 97..122 + 48..57)) })
}

# Generate OAuth2 Proxy cookie secret
$cookieSecret = New-RandomString -Length 32
Write-Host "✅ Generated OAuth2 Proxy cookie secret" -ForegroundColor Green

# Create .env file
$envContent = @"
# Environment variables for OIDC authentication
# Generated on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Keycloak Configuration
KEYCLOAK_CLIENT_ID=$ClientId
KEYCLOAK_CLIENT_SECRET=your-keycloak-client-secret-here
KEYCLOAK_REALM=$Realm
KEYCLOAK_BASE_URL=$KeycloakUrl

# OAuth2 Proxy Configuration
OAUTH2_PROXY_COOKIE_SECRET=$cookieSecret

# Domain Configuration
DOCS_DOMAIN=docs.yourdomain.com
DOCS_PORT=8080

# Security Settings
COOKIE_SECURE=false  # Set to true in production with HTTPS
SESSION_TIMEOUT=24h
REFRESH_INTERVAL=1h

# Access Control
ALLOWED_EMAIL_DOMAINS=*
ALLOWED_GROUPS=docs-readers,developers,architects,administrators

# Logging
LOG_LEVEL=info
ENABLE_REQUEST_LOGGING=true
ENABLE_AUTH_LOGGING=true
"@

$envContent | Out-File -FilePath ".env.oidc" -Encoding UTF8
Write-Host "✅ Created .env.oidc file" -ForegroundColor Green

# Update OAuth2 Proxy configuration
$proxyConfig = Get-Content "oauth2-proxy.cfg" -Raw
$proxyConfig = $proxyConfig -replace "https://sso\.yourdomain\.com", $KeycloakUrl
$proxyConfig = $proxyConfig -replace "itl-platform", $Realm
$proxyConfig | Out-File -FilePath "oauth2-proxy.cfg" -Encoding UTF8
Write-Host "✅ Updated OAuth2 Proxy configuration" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure Keycloak Client:" -ForegroundColor White
Write-Host "   - Go to: $KeycloakUrl/admin" -ForegroundColor Gray
Write-Host "   - Create client with ID: $ClientId" -ForegroundColor Gray
Write-Host "   - Set redirect URI: $DocsUrl/oauth2/callback" -ForegroundColor Gray
Write-Host "   - Copy client secret to .env.oidc file" -ForegroundColor Gray

Write-Host ""
Write-Host "2. Create Access Groups in Keycloak:" -ForegroundColor White
Write-Host "   - docs-readers: Read access to documentation" -ForegroundColor Gray
Write-Host "   - developers: Developer access" -ForegroundColor Gray
Write-Host "   - architects: Architecture documentation access" -ForegroundColor Gray
Write-Host "   - administrators: Full access" -ForegroundColor Gray

Write-Host ""
Write-Host "3. Deploy with OIDC:" -ForegroundColor White
Write-Host "   docker compose -f docker-compose.oidc.yml --env-file .env.oidc up -d --build" -ForegroundColor Gray

Write-Host ""
Write-Host "4. Test Authentication:" -ForegroundColor White
Write-Host "   - Access: $DocsUrl" -ForegroundColor Gray
Write-Host "   - You should be redirected to Keycloak login" -ForegroundColor Gray

Write-Host ""
Write-Host "🔧 Configuration Files Created:" -ForegroundColor Cyan
Write-Host "   - .env.oidc (environment variables)" -ForegroundColor Gray
Write-Host "   - oauth2-proxy.cfg (OAuth2 Proxy config)" -ForegroundColor Gray
Write-Host "   - docker-compose.oidc.yml (Docker Compose with OIDC)" -ForegroundColor Gray

Write-Host ""
Write-Host "🚀 Ready for OIDC deployment!" -ForegroundColor Green