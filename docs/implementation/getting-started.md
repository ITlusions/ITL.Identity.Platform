# Getting Started

This guide will walk you through implementing the ITL Identity Platform in your Kubernetes environment.

## Prerequisites

### Infrastructure Requirements

- **Kubernetes Clusters**: 
- 
  - 1 management cluster (for identity services)
  - 1+ workload clusters
  - Kubernetes 1.24+ with RBAC enabled

- **Network Requirements**:
- 
  - Inter-cluster connectivity for SPIRE federation
  - External DNS for service discovery
  - TLS certificate management (Let's Encrypt or internal CA)

- **External Dependencies**:
- 
  - External Secrets Operator with Azure KeyVault (or equivalent)
  - ArgoCD for GitOps deployment
  - Prometheus/Grafana for monitoring

### Access Requirements

- **Cluster Admin**: Initial setup requires cluster-admin privileges

- **DNS Management**: Ability to create DNS records for services

- **Certificate Authority**: Access to issue certificates or ACME registration

## Implementation Phases

### Phase 0: Foundations (2-3 weeks)

!!! info "Foundation Setup"
    This phase establishes the core identity infrastructure and security boundaries.

#### Keycloak Hardening

1. **Review Current Setup**:
   ```bash
   # Check existing Keycloak configuration
   kubectl get keycloak -n keycloak-system
   kubectl describe keycloak keycloak -n keycloak-system
   ```

2. **Enable Audit Logging**:
   ```yaml
   # keycloak-audit-config.yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: keycloak-audit-config
   data:
     keycloak.conf: |
       log-level=INFO
       spi-events-listener-jboss-logging-success-level=info
       spi-events-listener-jboss-logging-error-level=warn
   ```

3. **Configure MFA/ACR**:
   - Enable required actions for MFA
   - Configure authentication flows
   - Set up conditional access policies

#### SPIRE Deployment

1. **Install SPIRE Server**:
   ```bash
   # Add SPIRE Helm repository
   helm repo add spiffe https://spiffe.github.io/helm-charts-hardened/
   helm repo update
   
   # Install SPIRE Server
   helm install spire-server spiffe/spire \
     --namespace spire-system \
     --create-namespace \
     --values spire-server-values.yaml
   ```

2. **Deploy SPIRE Agents**:
   ```yaml
   # spire-agent-daemonset.yaml
   apiVersion: apps/v1
   kind: DaemonSet
   metadata:
     name: spire-agent
     namespace: spire-system
   spec:
     selector:
       matchLabels:
         app: spire-agent
     template:
       metadata:
         labels:
           app: spire-agent
       spec:
         serviceAccountName: spire-agent
         containers:
         - name: spire-agent
           image: ghcr.io/spiffe/spire-agent:1.8.0
           # Configuration details...
   ```

3. **Install OIDC Discovery Provider**:
   ```bash
   # Deploy OIDC Discovery Provider
   kubectl apply -f oidc-discovery-provider.yaml
   ```

#### Teleport Setup

1. **Install Teleport**:
   ```bash
   # Install Teleport using Helm
   helm repo add teleport https://charts.releases.teleport.dev
   helm install teleport teleport/teleport-cluster \
     --namespace teleport-system \
     --create-namespace \
     --values teleport-values.yaml
   ```

2. **Configure OIDC Connector**:
   ```yaml
   # teleport-oidc-connector.yaml
   kind: oidc
   version: v3
   metadata:
     name: keycloak
   spec:
     redirect_url: https://teleport.yourdomain.com/v1/webapi/oidc/callback
     client_id: teleport
     client_secret: <from-keycloak>
     issuer_url: https://sso.yourdomain.com/realms/your-realm
     scope: [openid, email, profile, groups]
     claims_to_roles:
       - claim: groups
         value: Eligible-K8sAdmin
         roles: [request.kube-admin]
   ```

### Phase 1: MVP Implementation (4-6 weeks)

!!! warning "Production Readiness"
    Ensure proper testing in development environments before production deployment.

#### Workload Registration

1. **Register Sample Workloads**:
   ```bash
   # Register a workload in SPIRE
   spire-server entry create \
     -parentID spiffe://synora.local/spire/agent/k8s_psat/cluster1 \
     -spiffeID spiffe://synora.local/ns/payments/sa/api \
     -selector k8s:ns:payments \
     -selector k8s:sa:api \
     -selector k8s:pod-label:app:payments-api
   ```

2. **Enable mTLS**:
   ```yaml
   # payment-api-deployment.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: payments-api
     namespace: payments
   spec:
     template:
       spec:
         serviceAccountName: api
         containers:
         - name: payments-api
           image: payments-api:latest
           volumeMounts:
           - name: spire-agent-socket
             mountPath: /tmp/spire-agent/public
             readOnly: true
         volumes:
         - name: spire-agent-socket
           hostPath:
             path: /run/spire/sockets
             type: Directory
   ```

#### Teleport Roles Configuration

1. **Create Requestable Roles**:
   ```yaml
   # k8s-admin-role.yaml
   kind: role
   version: v5
   metadata:
     name: request.kube-admin
   spec:
     allow:
       request:
         roles: ['kube-admin']
         thresholds:
           - approve: 1
             deny: 1
   ---
   kind: role
   version: v5
   metadata:
     name: kube-admin
   spec:
     allow:
       kubernetes_groups: ['system:masters']
       kubernetes_users: ['teleport-user']
   ```

2. **Configure Approval Workflow**:
   ```yaml
   # approval-plugin.yaml
   teleport:
     auth_service:
       authentication:
         type: oidc
       resources:
         - labels:
             teleport.dev/plugin: slack
           spec:
             settings:
               token: <slack-bot-token>
               channel: #access-requests
   ```

#### PIM Broker Implementation

1. **Deploy PIM Broker**:
   ```python
   # pim-broker/main.py
   from fastapi import FastAPI, HTTPException
   from keycloak import KeycloakOpenID
   import jwt
   
   app = FastAPI()
   
   @app.post("/token-exchange")
   async def exchange_token(jwt_svid: str, audience: str, scope: str):
       # Validate JWT-SVID
       # Perform Keycloak Token Exchange
       # Return elevated token
       pass
   ```

2. **Configure Token Exchange**:
   ```bash
   # Example token exchange request
   curl -XPOST https://sso.yourdomain.com/realms/your-realm/protocol/openid-connect/token \
     -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
     -d subject_token_type=urn:ietf:params:oauth:token-type:jwt \
     -d subject_token=$JWT_SVID \
     -d requested_token_type=urn:ietf:params:oauth:token-type:access_token \
     -d audience=orders-api \
     -d scope=orders:admin
   ```

### Phase 2: Scale-out (6-10 weeks)

#### Policy Enforcement

1. **Deploy OPA Gatekeeper**:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
   ```

2. **Implement Policies**:
   ```yaml
   # deny-static-secrets.yaml
   apiVersion: templates.gatekeeper.sh/v1beta1
   kind: ConstraintTemplate
   metadata:
     name: denystaticsecrets
   spec:
     crd:
       spec:
         names:
           kind: DenyStaticSecrets
         validation:
           properties:
             exemptNamespaces:
               type: array
               items:
                 type: string
     targets:
       - target: admission.k8s.gatekeeper.sh
         rego: |
           package denystaticsecrets
           
           violation[{"msg": msg}] {
             input.review.kind.kind == "Pod"
             container := input.review.object.spec.containers[_]
             env := container.env[_]
             contains(env.name, "PASSWORD")
             msg := "Static secrets not allowed"
           }
   ```

#### SIEM Integration

1. **Configure Log Forwarding**:
   ```yaml
   # fluent-bit-config.yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: fluent-bit-config
   data:
     fluent-bit.conf: |
       [OUTPUT]
           Name  forward
           Match auth.*
           Host  siem-collector.security.local
           Port  24224
   ```

### Phase 3: Optimization (Ongoing)

#### Automation

1. **GitOps SPIRE Entries**:
   ```yaml
   # spire-entries-configmap.yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: spire-entries
   data:
     entries.yaml: |
       entries:
         - spiffeID: spiffe://synora.local/ns/payments/sa/api
           selectors:
             - k8s:ns:payments
             - k8s:sa:api
   ```

2. **Automated Approvals**:
   ```yaml
   # auto-approval-policy.yaml
   kind: role
   version: v5
   metadata:
     name: auto-approve-dev
   spec:
     allow:
       request:
         roles: ['dev-readonly']
         thresholds:
           - approve: 0  # Auto-approve
   ```

## Validation Steps

### MVP Acceptance Criteria

1. **Human JIT Access**:
   ```bash
   # Request admin access
   tsh request create --roles=kube-admin --reason="Troubleshooting prod issue"
   
   # Verify access
   kubectl get nodes
   ```

2. **Workload Identity**:
   ```bash
   # Verify SVID issuance
   kubectl exec -it payments-api-pod -- \
     /opt/spire/bin/spire-agent api fetch jwt -audience orders-api
   ```

3. **Token Exchange**:
   ```bash
   # Test elevated token
   curl -H "Authorization: Bearer $ELEVATED_TOKEN" \
     https://orders-api.internal/admin/health
   ```

## Troubleshooting

### Common Issues

1. **SPIRE Agent Connection**:
   ```bash
   # Check agent logs
   kubectl logs -n spire-system daemonset/spire-agent
   
   # Verify socket mount
   kubectl exec -it spire-agent-pod -- ls -la /tmp/spire-agent/public/
   ```

2. **Teleport OIDC Issues**:
   ```bash
   # Check teleport auth logs
   kubectl logs -n teleport-system deployment/teleport-auth
   
   # Verify OIDC configuration
   tctl get oidc/keycloak
   ```

3. **Token Exchange Failures**:
   ```bash
   # Check Keycloak logs
   kubectl logs -n keycloak-system statefulset/keycloak
   
   # Verify client configuration
   kcadm.sh get clients -r your-realm --fields clientId,serviceAccountsEnabled
   ```

## Next Steps

- **[Component Details](components.md)** - Detailed configuration for each component
- **[Deployment Guide](../operations/deployment.md)** - Production deployment patterns
- **[Security Model](../security/security-model.md)** - Security architecture deep dive
- **[Monitoring](../operations/monitoring.md)** - Observability and alerting setup