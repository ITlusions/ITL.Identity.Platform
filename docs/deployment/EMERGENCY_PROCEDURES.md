# Emergency Deployment Procedures

This document outlines the emergency deployment procedures for the ITL Identity Platform documentation. Emergency deployments are designed for critical production issues that require immediate remediation.

## ⚠️ Important Warning

Emergency deployments bypass normal safety checks and testing procedures. Use only when absolutely necessary for production incidents.

## Overview

The ITL Identity Platform includes three comprehensive deployment workflows:

1. **Standard CI/CD Pipeline** (`build-deploy.yml`) - Normal tag-based deployments
2. **Version-Specific Deployment** (`deploy-version.yml`) - Deploy any specific version to any environment
3. **Branch Deployment** (`deploy-branch.yml`) - Deploy any branch to any environment
4. **Emergency Production Deployment** (`emergency-deploy.yml`) - Critical production fixes

## Emergency Deployment Workflow

### Trigger Requirements

Emergency deployments can only be triggered manually via GitHub Actions with the following required inputs:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `branch` | string | ✅ | Branch containing the emergency fix |
| `reason` | string | ✅ | Detailed reason for emergency deployment (min 10 chars) |
| `severity` | choice | ✅ | Incident severity: `critical`, `high`, `medium` |
| `skip_tests` | boolean | ❌ | Skip tests (critical emergencies only) |
| `force_deployment` | boolean | ❌ | Skip health checks (extreme emergencies) |
| `create_rollback_tag` | boolean | ❌ | Create rollback checkpoint (default: true) |
| `notify_oncall` | boolean | ❌ | Notify on-call team (default: true) |
| `rollback_timeout` | string | ❌ | Auto-rollback timeout in minutes (default: 30) |

### Safety Features

#### 1. Validation Requirements
- Emergency reason must be at least 10 characters
- Special warnings for critical severity deployments
- Alerts for test skipping or forced deployments
- Actor tracking and audit trail

#### 2. Rollback Protection
- **Automatic Rollback Checkpoint**: Creates snapshot of current production state
- **Auto-Rollback Scheduling**: Automatic rollback after specified timeout
- **Manual Rollback Instructions**: Provided in deployment summary
- **Previous State Tracking**: Captures current production image and version

#### 3. Deployment Verification
- **Health Checks**: Verifies deployment functionality (unless forced)
- **Pod Status Verification**: Ensures pods are running correctly
- **External Access Testing**: Validates public endpoint availability
- **Rollout Status Monitoring**: Confirms Kubernetes deployment completion

### Emergency Deployment Process

#### Phase 1: Emergency Validation
```yaml
Environment: emergency-production
Requirements:
  - Manual approval via GitHub environment protection
  - Emergency deployment justification
  - Severity level assessment
```

**Validation Steps:**
1. Validate emergency deployment request
2. Capture current production state
3. Create rollback tag and checkpoint
4. Generate emergency deployment tag

#### Phase 2: Emergency Build
```yaml
Permissions:
  - contents: read
  - packages: write
```

**Build Process:**
1. Checkout emergency branch
2. Run emergency tests (unless skipped)
3. Build multi-architecture Docker image
4. Tag with emergency metadata
5. Test image functionality (unless forced)

**Emergency Metadata Labels:**
- `emergency.deployment.reason`
- `emergency.deployment.severity`
- `emergency.deployment.actor`
- `emergency.deployment.timestamp`
- `emergency.rollback.tag`
- `emergency.rollback.previous-image`

#### Phase 3: Emergency Deploy
```yaml
Environment: production
Requirements:
  - Production environment approval
  - Kubernetes cluster access
  - Helm registry authentication
```

**Deployment Steps:**
1. Configure kubectl and Helm
2. Create rollback checkpoint files
3. Deploy with emergency configuration
4. Verify deployment health
5. Update ArgoCD ApplicationSet
6. Schedule auto-rollback (if requested)

### Emergency Configuration

Emergency deployments use production-grade configuration with additional metadata:

```yaml
# Emergency Production Values
image:
  repository: ghcr.io/itlusions/identity-docs
  tag: emergency-YYYYMMDD-HHMMSS-actor
  pullPolicy: Always

replicaCount: 2

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

# Emergency annotations
podAnnotations:
  emergency.deployment: "true"
  emergency.reason: "Critical production fix"
  emergency.severity: "critical"
  emergency.actor: "github-actor"
  emergency.branch: "hotfix-branch"
  emergency.timestamp: "2024-01-15T10:30:00Z"
  emergency.rollback-tag: "emergency-rollback-20240115-103000"
  emergency.previous-image: "ghcr.io/itlusions/identity-docs:v1.2.3"

# Auto-scaling for production load
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

## Rollback Procedures

### Automatic Rollback

Auto-rollback is scheduled when `rollback_timeout` is set to a value greater than 0:

```yaml
# Auto-rollback job specification
apiVersion: batch/v1
kind: Job
metadata:
  name: emergency-auto-rollback-timestamp
  namespace: docs
spec:
  ttlSecondsAfterFinished: 3600
  template:
    spec:
      containers:
      - name: auto-rollback
        image: bitnami/kubectl:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          sleep $((ROLLBACK_MINUTES * 60))
          kubectl set image deployment/identity-docs identity-docs=PREVIOUS_IMAGE -n docs
          kubectl rollout status deployment/identity-docs -n docs
```

### Manual Rollback

#### Quick Rollback Commands

```bash
# Rollback to previous production version
kubectl set image deployment/identity-docs \
  identity-docs=ghcr.io/itlusions/identity-docs:v1.2.3 \
  -n docs

# Monitor rollback status
kubectl rollout status deployment/identity-docs -n docs --timeout=300s

# Verify rollback
kubectl get pods -n docs -l app.kubernetes.io/name=identity-docs
```

#### Using Rollback Checkpoint Files

```bash
# Apply saved deployment state
kubectl apply -f emergency-rollback-deployment.yaml
kubectl apply -f emergency-rollback-service.yaml
kubectl apply -f emergency-rollback-ingress.yaml

# Monitor restoration
kubectl rollout status deployment/identity-docs -n docs
```

#### ArgoCD Rollback

```bash
# Revert ArgoCD ApplicationSet changes
kubectl apply -f argocd/applicationset.yaml

# Force ArgoCD sync to previous state
argocd app sync identity-docs-production --force
```

## Incident Response

### Critical Severity (severity: critical)

**Characteristics:**
- Service completely unavailable
- Data loss risk
- Security breach
- Complete functionality failure

**Emergency Response:**
```bash
# Example: Critical security vulnerability fix
gh workflow run emergency-deploy.yml \
  -f branch=security-hotfix-cve-2024-001 \
  -f reason="Critical security vulnerability CVE-2024-001 - immediate patching required" \
  -f severity=critical \
  -f skip_tests=true \
  -f force_deployment=false \
  -f rollback_timeout=15
```

### High Severity (severity: high)

**Characteristics:**
- Major functionality impaired
- Performance severely degraded
- Affecting multiple users
- Business-critical features down

**Emergency Response:**
```bash
# Example: Major functionality fix
gh workflow run emergency-deploy.yml \
  -f branch=hotfix-auth-issue \
  -f reason="Authentication system failure preventing user access" \
  -f severity=high \
  -f skip_tests=false \
  -f rollback_timeout=30
```

### Medium Severity (severity: medium)

**Characteristics:**
- Minor functionality issues
- Limited user impact
- Performance issues
- Non-critical feature problems

**Emergency Response:**
```bash
# Example: Performance optimization
gh workflow run emergency-deploy.yml \
  -f branch=fix-memory-leak \
  -f reason="Memory leak causing gradual performance degradation" \
  -f severity=medium \
  -f rollback_timeout=60
```

## Monitoring and Alerting

### Deployment Tracking

Emergency deployments are tracked through multiple channels:

1. **GitHub Actions Logs**: Complete deployment history
2. **Kubernetes Annotations**: Emergency metadata on pods
3. **Container Labels**: Emergency deployment information
4. **Teams Notifications**: Real-time deployment status
5. **On-Call Notifications**: Critical incident alerts

### Post-Deployment Monitoring

After emergency deployment, monitor:

```bash
# Pod health
kubectl get pods -n docs -l app.kubernetes.io/name=identity-docs -w

# Deployment status
kubectl describe deployment identity-docs -n docs

# Service endpoints
kubectl get endpoints identity-docs -n docs

# Resource usage
kubectl top pods -n docs -l app.kubernetes.io/name=identity-docs

# Application logs
kubectl logs -f deployment/identity-docs -n docs

# External access verification
curl -I https://docs.itlusions.com/identity/
```

### Emergency Metrics

Key metrics to monitor during emergency deployments:

- **Response Time**: Application response latency
- **Error Rate**: HTTP error responses
- **Memory Usage**: Container memory consumption
- **CPU Usage**: Container CPU utilization
- **Pod Restarts**: Container restart frequency
- **Health Check Success**: Liveness/readiness probe status

## Best Practices

### Emergency Preparation

1. **Keep Hotfix Branches Ready**: Maintain prepared branches for common issues
2. **Test Emergency Procedures**: Regular drills for emergency deployment process
3. **Maintain Rollback Documentation**: Updated rollback procedures and commands
4. **Monitor Production Continuously**: Early detection prevents emergencies
5. **Document Known Issues**: Catalog of common problems and solutions

### During Emergency

1. **Document Everything**: Detailed incident timeline and actions
2. **Communicate Clearly**: Regular updates to stakeholders
3. **Follow Approval Process**: Respect environment protection rules
4. **Monitor Closely**: Continuous observation post-deployment
5. **Prepare for Rollback**: Have rollback plan ready before deployment

### Post-Emergency

1. **Conduct Post-Mortem**: Analyze incident cause and response
2. **Update Procedures**: Improve emergency processes based on learnings
3. **Create Proper Fix**: Develop and test permanent solution
4. **Deploy Stable Version**: Replace emergency fix with tested solution
5. **Update Documentation**: Capture lessons learned

## Security Considerations

### Access Control

Emergency deployments require specific permissions:

- **GitHub Repository**: Admin or emergency deployment team membership
- **Production Environment**: Manual approval required
- **Kubernetes Cluster**: Appropriate RBAC permissions
- **Container Registry**: Push/pull access to emergency images

### Audit Trail

Every emergency deployment creates a complete audit trail:

```json
{
  "emergency_deployment": {
    "timestamp": "2024-01-15T10:30:00Z",
    "actor": "incident-responder",
    "branch": "security-hotfix-cve-2024-001",
    "reason": "Critical security vulnerability requires immediate patching",
    "severity": "critical",
    "skip_tests": true,
    "force_deployment": false,
    "emergency_tag": "emergency-20240115-103000-incident-responder",
    "rollback_tag": "emergency-rollback-20240115-103000",
    "previous_image": "ghcr.io/itlusions/identity-docs:v1.2.3",
    "workflow_run": "https://github.com/ITLusions/ITL.identity.platform/actions/runs/123456"
  }
}
```

### Compliance

Emergency deployments maintain compliance through:

- **Change Approval**: Environment protection rules
- **Documentation Requirements**: Mandatory reason and audit trail
- **Rollback Capability**: Automatic rollback checkpoints
- **Monitoring**: Continuous deployment tracking
- **Notification**: Automatic stakeholder alerts

## Troubleshooting

### Common Emergency Deployment Issues

#### 1. Authentication Failures

```bash
# Re-authenticate with container registry
docker login ghcr.io -u USERNAME -p TOKEN

# Verify Kubernetes access
kubectl cluster-info
kubectl auth can-i create deployments --namespace docs
```

#### 2. Image Build Failures

```bash
# Check Docker daemon
docker info

# Verify Dockerfile syntax
docker build --no-cache -t test-image .

# Check multi-architecture support
docker buildx ls
```

#### 3. Deployment Timeouts

```bash
# Check node resources
kubectl describe nodes

# Verify image pull status
kubectl describe pods -n docs -l app.kubernetes.io/name=identity-docs

# Check resource limits
kubectl get limitranges -n docs
```

#### 4. Health Check Failures

```bash
# Test application directly
kubectl port-forward deployment/identity-docs 8080:80 -n docs
curl http://localhost:8080/

# Check application logs
kubectl logs deployment/identity-docs -n docs --tail=100

# Verify readiness probe
kubectl describe deployment identity-docs -n docs
```

### Emergency Contacts

| Role | Contact | Availability |
|------|---------|--------------|
| Platform Team Lead | @platform-lead | 24/7 |
| DevOps Engineer | @devops-engineer | Business Hours |
| Security Team | @security-team | 24/7 |
| On-Call Engineer | Automated via webhook | 24/7 |

### Recovery Procedures

If emergency deployment fails completely:

1. **Immediate Rollback**:
   ```bash
   kubectl apply -f emergency-rollback-deployment.yaml
   kubectl rollout status deployment/identity-docs -n docs
   ```

2. **Service Restoration**:
   ```bash
   kubectl scale deployment identity-docs --replicas=3 -n docs
   kubectl get pods -n docs -w
   ```

3. **Incident Escalation**:
   - Notify platform team lead
   - Create critical incident ticket
   - Activate incident response team
   - Communicate to stakeholders

4. **Alternative Deployment**:
   - Use standard deployment pipeline
   - Deploy from stable branch
   - Verify service restoration
   - Plan proper emergency fix

Remember: Emergency deployments are designed for critical situations only. Use standard deployment procedures whenever possible.