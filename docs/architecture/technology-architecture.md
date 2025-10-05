# Technology Architecture (TOGAF Phase D)

This document defines the technology components, patterns, and infrastructure architecture that supports the ITL Identity Platform solution.

## Technology Components

### Core Technology Stack

#### Identity and Authentication Technologies

**Keycloak Identity Provider**

```yaml
technology: Keycloak 23.x
purpose: Enterprise Identity and Access Management
characteristics:
  - Multi-realm support for tenant isolation
  - OIDC/OAuth 2.0/SAML compliance
  - External IdP federation capabilities
  - Comprehensive admin and user APIs
deployment:
  runtime: Java 17+ on Kubernetes
  database: PostgreSQL 15+
  storage: 50GB+ for production workloads
  memory: 4GB+ heap for 10,000+ users
  cpu: 2+ cores for production load
high_availability:
  clustering: JGroups-based clustering
  load_balancing: Multiple instances behind load balancer
  database: PostgreSQL high availability cluster
  session_replication: Infinispan distributed cache
```

**SPIRE (SPIFFE Runtime Environment)**

```yaml
spire_server:
  technology: SPIRE Server 1.8+
  purpose: SPIFFE identity issuance and workload attestation
  characteristics:
    - X.509 and JWT-SVID issuance
    - Pluggable attestation framework
    - Federation capabilities
    - Certificate authority operations
  deployment:
    runtime: Go binary on Kubernetes
    database: PostgreSQL or SQLite
    storage: HSM or software-based CA keys
    memory: 512MB+ for production
    cpu: 1+ core recommended

spire_agent:
  technology: SPIRE Agent 1.8+
  purpose: Workload identity client and attestation
  characteristics:
    - Kubernetes workload attestation
    - Unix domain socket API
    - Automatic certificate rotation
    - Local SVID caching
  deployment:
    runtime: Go binary as Kubernetes DaemonSet
    storage: Ephemeral local storage
    memory: 256MB per node
    cpu: 0.5 core recommended
    privileges: Requires privileged access for attestation
```

#### Infrastructure Access Technologies

**Teleport Infrastructure Access**

```yaml
teleport_cluster:
  technology: Teleport Enterprise 14+
  purpose: Infrastructure access gateway and session management
  characteristics:
    - SSH and Kubernetes API proxying
    - Session recording and audit
    - RBAC and access request workflows
    - Certificate-based authentication
  deployment:
    runtime: Go binary cluster on Kubernetes
    database: DynamoDB or etcd for cluster state
    storage: S3-compatible for session recordings
    memory: 2GB+ for production cluster
    cpu: 2+ cores recommended

teleport_agents:
  technology: Teleport Agent 14+
  purpose: Resource access proxy
  deployment:
    runtime: Go binary on target systems
    memory: 128MB per agent
    cpu: 0.1 core typical usage
    networking: Reverse tunnel to cluster
```

#### Policy and Governance Technologies

**Open Policy Agent (OPA)**

```yaml
opa_gatekeeper:
  technology: OPA Gatekeeper 3.14+
  purpose: Kubernetes admission control and policy enforcement
  characteristics:
    - Constraint template framework
    - Rego policy language
    - Mutating and validating webhooks
    - Policy violation reporting
  deployment:
    runtime: Go binary on Kubernetes
    memory: 512MB for controller + 256MB per replica
    cpu: 0.5 core for controller + 0.1 core per replica

opa_standalone:
  technology: OPA 0.58+
  purpose: Application-level policy decisions
  deployment:
    runtime: Go binary or library integration
    memory: 128MB+ depending on policy bundle size
    cpu: 0.1 core typical usage
    networking: REST API or library calls
```

### Supporting Technology Components

#### Monitoring and Observability

**Prometheus Monitoring Stack**

```yaml
prometheus_server:
  technology: Prometheus 2.48+
  purpose: Metrics collection and time-series storage
  characteristics:
    - PromQL query language
    - Service discovery integration
    - Alert rule evaluation
    - Federation capabilities
  deployment:
    runtime: Go binary on Kubernetes
    storage: 500GB+ for 30-day retention
    memory: 8GB+ for large environments
    cpu: 2+ cores recommended

alertmanager:
  technology: Alertmanager 0.26+
  purpose: Alert routing and notification management
  deployment:
    runtime: Go binary on Kubernetes
    memory: 256MB typical
    cpu: 0.1 core typical usage

grafana:
  technology: Grafana 10.2+
  purpose: Metrics visualization and dashboarding
  deployment:
    runtime: Go binary on Kubernetes
    database: PostgreSQL for dashboard storage
    memory: 1GB+ for production
    cpu: 1+ core recommended
```

**Logging Infrastructure**

```yaml
elasticsearch_cluster:
  technology: Elasticsearch 8.11+
  purpose: Log aggregation and search
  characteristics:
    - Full-text search capabilities
    - JSON document storage
    - Distributed architecture
    - Security features (TLS, RBAC)
  deployment:
    runtime: Java on Kubernetes
    storage: 1TB+ per node for production
    memory: 16GB+ heap per node
    cpu: 4+ cores per node recommended
    cluster_size: 3+ nodes for high availability

fluentd:
  technology: Fluentd 1.16+
  purpose: Log collection and forwarding
  deployment:
    runtime: Ruby on Kubernetes DaemonSet
    memory: 512MB per node
    cpu: 0.5 core per node
    buffering: Local disk for reliability
```

#### Container Platform

**Kubernetes Container Orchestration**

```yaml
kubernetes_control_plane:
  technology: Kubernetes 1.28+
  components:
    - kube-apiserver: API gateway and admission control
    - etcd: Cluster state storage
    - kube-scheduler: Pod placement decisions
    - kube-controller-manager: Control loop management
  deployment:
    high_availability: 3+ control plane nodes
    etcd_storage: SSD with regular backups
    api_server_memory: 4GB+ per instance
    api_server_cpu: 2+ cores per instance

kubernetes_worker_nodes:
  technology: Kubernetes 1.28+ with containerd
  characteristics:
    - Container runtime: containerd 1.7+
    - Network CNI: Calico or similar
    - Storage CSI: Cloud provider specific
  deployment:
    node_memory: 16GB+ per worker node
    node_cpu: 4+ cores per worker node
    node_storage: 100GB+ system disk + additional storage
```

**Container Registry**

```yaml
container_registry:
  technology: Harbor 2.9+ or cloud provider registry
  purpose: Container image storage and security scanning
  characteristics:
    - Vulnerability scanning integration
    - Image signing and verification
    - Replication capabilities
    - RBAC integration
  deployment:
    storage: S3-compatible for image layers
    database: PostgreSQL for metadata
    memory: 2GB+ for Harbor core
    cpu: 1+ core recommended
```

### Database Technologies

#### Primary Data Storage

**PostgreSQL Database Clusters**

```yaml
keycloak_database:
  technology: PostgreSQL 15+
  purpose: Keycloak identity data storage
  characteristics:
    - ACID compliance for user data
    - Row-level security capabilities
    - JSON/JSONB support for flexible schemas
    - Full-text search capabilities
  deployment:
    high_availability: Streaming replication with failover
    storage: 200GB+ for production (depends on user count)
    memory: 8GB+ shared buffers
    cpu: 4+ cores recommended
    backup: Point-in-time recovery with 30-day retention

spire_database:
  technology: PostgreSQL 15+ or SQLite
  purpose: SPIFFE entry and certificate storage
  characteristics:
    - Strong consistency for cryptographic data
    - Efficient storage of certificate chains
    - Support for CA key protection
  deployment:
    storage: 50GB+ for production
    memory: 4GB+ shared buffers
    cpu: 2+ cores recommended
    backup: Continuous backup with HSM key protection
```

#### Time-Series Storage

**Prometheus Storage**

```yaml
prometheus_storage:
  technology: Prometheus TSDB
  characteristics:
    - Compressed time-series data
    - Sample-based storage model
    - Efficient range queries
    - Block-based storage with compaction
  deployment:
    storage: 2-byte per sample (500GB for 30-day retention)
    retention: 30 days high resolution, 1 year downsampled
    backup: Snapshots to object storage
```

### Network Technologies

#### Service Mesh Architecture

**Istio Service Mesh**

```yaml
istio_control_plane:
  technology: Istio 1.19+
  components:
    - istiod: Control plane with Pilot, Citadel, Galley
    - ingress_gateway: Traffic ingress management
    - egress_gateway: Traffic egress control
  characteristics:
    - mTLS by default between services
    - Traffic management and routing
    - Security policy enforcement
    - Observability integration
  deployment:
    memory: 1GB+ for istiod
    cpu: 1+ core for istiod
    gateway_memory: 512MB+ per gateway
    gateway_cpu: 0.5+ core per gateway

istio_data_plane:
  technology: Envoy Proxy sidecars
  purpose: Service-to-service communication proxy
  characteristics:
    - L7 traffic management
    - mTLS termination and origination
    - Telemetry collection
    - Policy enforcement
  deployment:
    memory: 256MB+ per sidecar
    cpu: 0.1+ core per sidecar
    networking: Transparent proxy configuration
```

#### Load Balancing and Ingress

**Traefik Ingress Controller**

```yaml
traefik_ingress:
  technology: Traefik 3.0+
  purpose: HTTP/HTTPS ingress and load balancing
  characteristics:
    - Automatic service discovery
    - Let's Encrypt integration
    - Multiple provider support
    - Dynamic configuration
  deployment:
    runtime: Go binary on Kubernetes
    memory: 512MB+ for production
    cpu: 1+ core recommended
    networking: LoadBalancer or NodePort service
```

### Security Technologies

#### Certificate Management

**cert-manager Certificate Automation**

```yaml
cert_manager:
  technology: cert-manager 1.13+
  purpose: Certificate lifecycle automation
  characteristics:
    - Let's Encrypt ACME integration
    - Internal CA certificate issuance
    - Automatic renewal and rotation
    - Kubernetes native resources
  deployment:
    runtime: Go binary on Kubernetes
    memory: 256MB typical
    cpu: 0.1 core typical usage
    storage: Persistent volume for CA data
```

#### Secrets Management

**External Secrets Operator**

```yaml
external_secrets:
  technology: External Secrets Operator 0.9+
  purpose: Secret synchronization from external systems
  characteristics:
    - Multiple provider support (AWS, Azure, Vault)
    - Automatic secret rotation
    - Template-based secret generation
    - Audit logging
  deployment:
    runtime: Go binary on Kubernetes
    memory: 256MB typical
    cpu: 0.1 core typical usage
    permissions: Read access to external secret stores
```

**HashiCorp Vault (Optional)**

```yaml
vault_cluster:
  technology: Vault Enterprise 1.15+
  purpose: Centralized secrets management
  characteristics:
    - Dynamic secret generation
    - Transit encryption as a service
    - PKI certificate authority
    - Audit logging and compliance
  deployment:
    high_availability: Raft consensus with 3+ nodes
    storage: Integrated storage or external backend
    memory: 2GB+ per instance
    cpu: 1+ core per instance
    unseal: Auto-unseal with cloud KMS
```

## Technology Architecture Patterns

### Deployment Patterns

#### Multi-Cluster Architecture

```mermaid
flowchart TB
    subgraph "Management Cluster"
        KC[Keycloak]
        SPIRE_S[SPIRE Server]
        TP_C[Teleport Cluster]
        PIM[PIM Broker]
        OIDC[OIDC Provider]
    end
    
    subgraph "Workload Cluster 1"
        SA1[SPIRE Agent]
        OPA1[OPA Gatekeeper]
        TP_A1[Teleport Agent]
    end
    
    subgraph "Workload Cluster 2"
        SA2[SPIRE Agent]
        OPA2[OPA Gatekeeper]
        TP_A2[Teleport Agent]
    end
    
    SPIRE_S -.->|Federation| SA1
    SPIRE_S -.->|Federation| SA2
    TP_C -.->|Reverse Tunnel| TP_A1
    TP_C -.->|Reverse Tunnel| TP_A2
    KC -.->|Token Validation| OPA1
    KC -.->|Token Validation| OPA2
```

#### High Availability Patterns

**Active-Active Deployment**

```yaml
high_availability_pattern:
  type: Active-Active
  components:
    - keycloak: Multiple instances with database clustering
    - spire_server: Clustered deployment with shared database
    - teleport: Native clustering support
  characteristics:
    - Load distribution across instances
    - Automatic failover capabilities
    - Session affinity where required
    - Database replication for consistency
```

**Cross-Region Disaster Recovery**

```yaml
disaster_recovery:
  primary_region: us-east-1
  secondary_region: us-west-2
  replication:
    database: Asynchronous cross-region replication
    storage: Cross-region backup storage
    secrets: Multi-region secret replication
  recovery_time_objective: 4 hours
  recovery_point_objective: 1 hour
  failover: Manual failover with automated health checks
```

### Integration Patterns

#### API Gateway Pattern

```mermaid
flowchart LR
    C[Client] --> AG[API Gateway]
    AG --> KC[Keycloak APIs]
    AG --> SPIRE[SPIRE APIs]
    AG --> TP[Teleport APIs]
    AG --> PIM[PIM Broker APIs]
    
    AG --> Auth[Authentication]
    AG --> RL[Rate Limiting]
    AG --> Audit[Audit Logging]
```

**Gateway Configuration**

```yaml
api_gateway:
  technology: Traefik or Istio Gateway
  features:
    - Authentication: OIDC integration with Keycloak
    - Authorization: JWT validation and RBAC
    - Rate limiting: Per-user and per-endpoint limits
    - Audit logging: All API calls logged
    - Circuit breaking: Fault tolerance patterns
  routing:
    - /auth/*: Keycloak services
    - /identity/*: SPIRE and identity services
    - /access/*: Teleport and access services
    - /api/*: Application APIs
```

#### Event-Driven Integration

```mermaid
flowchart LR
    subgraph "Event Producers"
        KC[Keycloak]
        SPIRE[SPIRE Server]
        TP[Teleport]
    end
    
    subgraph "Event Infrastructure"
        EB[Event Bus]
        ES[Event Store]
    end
    
    subgraph "Event Consumers"
        AUDIT[Audit Service]
        NOTIFY[Notification Service]
        METRICS[Metrics Service]
    end
    
    KC --> EB
    SPIRE --> EB
    TP --> EB
    
    EB --> ES
    EB --> AUDIT
    EB --> NOTIFY
    EB --> METRICS
```

### Security Architecture Patterns

#### Zero Trust Network Architecture

```yaml
zero_trust_implementation:
  network_segmentation:
    - Kubernetes network policies
    - Service mesh mTLS enforcement
    - Micro-segmentation by namespace
  
  identity_verification:
    - SPIFFE identity for all workloads
    - User authentication via OIDC
    - Device attestation where applicable
  
  least_privilege_access:
    - RBAC with minimal permissions
    - Just-in-time access via Teleport
    - Policy-based access control
  
  encryption_everywhere:
    - TLS 1.3 for all communications
    - Encryption at rest for all data stores
    - Certificate-based service authentication
```

#### Defense in Depth

```yaml
security_layers:
  perimeter_security:
    - WAF for HTTP/HTTPS traffic
    - DDoS protection at cloud provider level
    - IP allowlisting for administrative access
  
  network_security:
    - VPC/VNET isolation
    - Network security groups/firewalls
    - Service mesh security policies
  
  application_security:
    - Container image scanning
    - Admission control with OPA Gatekeeper
    - Runtime security monitoring
  
  data_security:
    - Encryption at rest and in transit
    - Database access controls
    - Audit logging for all data access
```

### Performance and Scalability Patterns

#### Horizontal Scaling Patterns

```yaml
scaling_strategies:
  keycloak:
    strategy: Horizontal Pod Autoscaler (HPA)
    metrics: CPU utilization > 70%
    min_replicas: 3
    max_replicas: 10
    database: Read replicas for query load
  
  spire_agents:
    strategy: DaemonSet (one per node)
    scaling: Automatic with cluster node scaling
    resources: Resource requests/limits per node
  
  opa_gatekeeper:
    strategy: HPA based on admission webhook latency
    metrics: Request latency > 100ms
    min_replicas: 2
    max_replicas: 5
```

#### Caching Patterns

```yaml
caching_strategies:
  application_level:
    - Keycloak: Infinispan distributed cache
    - SPIRE Agent: Local SVID caching
    - OPA: Policy bundle caching
  
  infrastructure_level:
    - CDN: Static asset caching
    - API Gateway: Response caching for read operations
    - Database: Query result caching
  
  cache_invalidation:
    - Time-based expiration
    - Event-driven invalidation
    - Manual cache clearing capabilities
```

### Monitoring and Observability Patterns

#### Three Pillars of Observability

**Metrics Collection**

```yaml
metrics_architecture:
  collection: Prometheus with service discovery
  storage: Prometheus TSDB with remote storage
  visualization: Grafana dashboards
  alerting: Alertmanager with multiple notification channels
  
  key_metrics:
    - Authentication success/failure rates
    - Certificate issuance and renewal rates
    - API response times and error rates
    - Resource utilization (CPU, memory, storage)
```

**Distributed Tracing**

```yaml
tracing_architecture:
  collection: OpenTelemetry collectors
  storage: Jaeger or cloud provider tracing
  correlation: Trace correlation across service boundaries
  sampling: Head-based sampling with error trace preservation
  
  instrumentation:
    - Automatic: Service mesh sidecar injection
    - Manual: Application-level instrumentation
    - Context propagation: Across async operations
```

**Centralized Logging**

```yaml
logging_architecture:
  collection: Fluentd daemonset on all nodes
  aggregation: Elasticsearch cluster
  visualization: Kibana or Grafana
  retention: 90 days for operational logs, 7 years for audit logs
  
  log_structure:
    - Structured JSON logging
    - Correlation IDs for request tracing
    - Security event classification
    - Privacy-aware log sanitization
```

## Infrastructure Specifications

### Compute Requirements

#### Production Environment Sizing

**Management Cluster**

```yaml
management_cluster_sizing:
  nodes: 6 (3 control plane + 3 worker)
  node_specifications:
    cpu: 8 cores per node
    memory: 32GB per node
    storage: 100GB system + 500GB additional
    network: 10Gbps network connectivity
  
  workload_distribution:
    control_plane_nodes:
      - etcd: 2GB memory, 2 CPU cores
      - api_server: 4GB memory, 2 CPU cores
      - scheduler: 1GB memory, 1 CPU core
      - controller_manager: 2GB memory, 1 CPU core
    
    worker_nodes:
      - keycloak: 4GB memory, 2 CPU cores
      - spire_server: 1GB memory, 1 CPU core
      - teleport_cluster: 2GB memory, 2 CPU cores
      - prometheus: 8GB memory, 2 CPU cores
      - elasticsearch: 16GB memory, 4 CPU cores
```

**Workload Clusters**

```yaml
workload_cluster_sizing:
  nodes: 3+ (depending on workload requirements)
  node_specifications:
    cpu: 4+ cores per node
    memory: 16+ GB per node
    storage: 100GB system + workload-specific storage
    network: 1Gbps+ network connectivity
  
  platform_overhead:
    - spire_agent: 256MB memory, 0.1 CPU core per node
    - opa_gatekeeper: 512MB memory, 0.1 CPU core
    - monitoring_agents: 512MB memory, 0.2 CPU core per node
    - istio_sidecar: 256MB memory per pod with sidecar
```

### Storage Requirements

#### Persistent Storage Classes

```yaml
storage_classes:
  high_performance:
    type: SSD/NVMe storage
    use_cases:
      - etcd data
      - Database storage (PostgreSQL)
      - Elasticsearch indices
    characteristics:
      - Low latency (< 1ms)
      - High IOPS (10,000+)
      - Automatic backup capabilities
  
  standard_performance:
    type: Standard SSD storage
    use_cases:
      - Application logs
      - Prometheus metrics
      - Container image layers
    characteristics:
      - Moderate latency (< 10ms)
      - Standard IOPS (1,000+)
      - Cost-effective for bulk storage
  
  archive_storage:
    type: Object storage (S3/Blob)
    use_cases:
      - Long-term audit logs
      - Backup storage
      - Session recordings
    characteristics:
      - High durability (99.999999999%)
      - Lower cost per GB
      - Lifecycle management policies
```

### Network Architecture

#### Network Segmentation

```yaml
network_segmentation:
  management_network:
    purpose: Control plane and management services
    subnet: 10.0.1.0/24
    access: Restricted to administrative users
    security: Enhanced logging and monitoring
  
  application_network:
    purpose: Application workloads and data flow
    subnet: 10.0.10.0/16
    access: Application-to-application communication
    security: Service mesh mTLS enforcement
  
  external_network:
    purpose: Internet-facing services
    access: Public internet through load balancer
    security: WAF and DDoS protection
```

#### Load Balancer Configuration

```yaml
load_balancer_tiers:
  external_load_balancer:
    type: Cloud provider load balancer (L4/L7)
    purpose: Internet traffic ingress
    configuration:
      - SSL termination
      - Health check integration
      - DDoS protection
      - Geographic load balancing
  
  internal_load_balancer:
    type: Kubernetes Service (ClusterIP/LoadBalancer)
    purpose: Internal service communication
    configuration:
      - Service discovery integration
      - Session affinity where required
      - Circuit breaker patterns
```

---

## Reference Configuration Examples

### Teleport Integration Configuration

**Teleport OIDC Connector (to Keycloak)**

```yaml
kind: oidc
version: v3
metadata:
  name: keycloak
spec:
  redirect_url: https://teleport.<domain>/v1/webapi/oidc/callback
  client_id: teleport
  client_secret: <secret>
  issuer_url: https://sso.<domain>/realms/<tenant>
  scope: [openid, email, profile, groups]
  claims_to_roles:
    - claim: groups
      value: Eligible-K8sAdmin
      roles: [request.kube-admin]
    - claim: groups
      value: Eligible-DBAdmin
      roles: [request.db-admin]
```

**Teleport Role Definition**

```yaml
kind: role
version: v6
metadata:
  name: kube-admin
spec:
  allow:
    kubernetes_groups: ["system:masters"]
    kubernetes_users: ["teleport-user"]
    kubernetes_labels:
      environment: ["production", "staging"]
    request:
      roles: ["kube-admin"]
      thresholds:
        - approve: 1
          deny: 1
      suggested_reviewers: ["security-team"]
  options:
    max_session_ttl: 1h
    client_idle_timeout: 30m
```

### SPIRE Configuration

**SPIRE Server Configuration**

```yaml
server:
  bind_address: "0.0.0.0"
  bind_port: "8081"
  trust_domain: "synora.local"
  data_dir: "/opt/spire/data/server"
  log_level: "INFO"
  ca_key_type: "rsa-2048"
  ca_ttl: "720h"
  default_x509_svid_ttl: "1h"
  default_jwt_svid_ttl: "15m"

plugins:
  DataStore:
    sql:
      plugin_data:
        database_type: "postgres"
        connection_string: "postgres://spire:password@postgres:5432/spire"
  
  NodeAttestor:
    k8s_psat:
      plugin_data:
        clusters:
          cluster1:
            service_account_allow_list: ["spire:spire-agent"]
            audience: ["spire-server"]
  
  KeyManager:
    disk:
      plugin_data:
        keys_path: "/opt/spire/data/server/keys.json"
  
  Upstreams:
    disk:
      plugin_data:
        cert_file_path: "/opt/spire/conf/server/ca.crt"
        key_file_path: "/opt/spire/conf/server/ca.key"
```

**SPIRE Registration Examples**

```bash
# Register workload identity for payments API
spire-server entry create \
  -parentID spiffe://synora.local/spire/agent/k8s_psat/cluster1 \
  -spiffeID spiffe://synora.local/ns/payments/sa/api \
  -selector k8s:ns:payments \
  -selector k8s:sa:api \
  -selector k8s:pod-label:app:payments-api \
  -ttl 3600

# Register workload identity for database access
spire-server entry create \
  -parentID spiffe://synora.local/spire/agent/k8s_psat/cluster1 \
  -spiffeID spiffe://synora.local/ns/orders/sa/processor \
  -selector k8s:ns:orders \
  -selector k8s:sa:processor \
  -selector k8s:pod-label:component:order-processor \
  -ttl 3600
```

### Keycloak Token Exchange Configuration

**Token Exchange Request Example**

```bash
# Application requesting elevated token via Token Exchange
curl -XPOST https://sso.<domain>/realms/<tenant>/protocol/openid-connect/token \
  -d grant_type=urn:ietf:params:oauth:grant-type:token-exchange \
  -d subject_token_type=urn:ietf:params:oauth:token-type:jwt \
  -d subject_token=$JWT_SVID \
  -d requested_token_type=urn:ietf:params:oauth:token-type:access_token \
  -d audience=orders-api \
  -d scope="orders:admin" \
  -d client_id=pim-broker \
  -d client_secret=$CLIENT_SECRET
```

**Keycloak Client Configuration for Token Exchange**

```json
{
  "clientId": "pim-broker",
  "enabled": true,
  "clientAuthenticatorType": "client-secret",
  "secret": "pim-broker-secret",
  "standardFlowEnabled": false,
  "serviceAccountsEnabled": true,
  "authorizationServicesEnabled": true,
  "attributes": {
    "token.endpoint.auth.signing.alg": "RS256",
    "oauth2.device.authorization.grant.enabled": false,
    "oidc.ciba.grant.enabled": false,
    "oauth2.token.exchange.grant.enabled": true
  },
  "protocolMappers": [
    {
      "name": "audience-mapper",
      "protocol": "openid-connect",
      "protocolMapper": "oidc-audience-mapper",
      "config": {
        "included.client.audience": "orders-api",
        "id.token.claim": "false",
        "access.token.claim": "true"
      }
    }
  ]
}
```

### OPA Policy Examples

**SPIFFE Identity Enforcement Policy**

```rego
package kubernetes.admission

import rego.v1

# Deny pods in production namespaces without SPIFFE identity
deny contains msg if {
    input.request.kind.kind == "Pod"
    input.request.namespace == "production"
    not has_spiffe_annotation
    msg := "Pods in production namespace must have SPIFFE identity annotation"
}

has_spiffe_annotation if {
    input.request.object.metadata.annotations["spiffe.io/trust-domain"]
}

# Deny static secret mounts for apps with JIT pattern
deny contains msg if {
    input.request.kind.kind == "Pod"
    input.request.object.metadata.labels["auth-pattern"] == "jit"
    has_static_secret_volume
    msg := "Applications using JIT auth pattern cannot mount static secrets"
}

has_static_secret_volume if {
    some volume in input.request.object.spec.volumes
    volume.secret
    not startswith(volume.secret.secretName, "spire-")
}
```

**Token Audience Validation Policy**

```rego
package tokens.validation

import rego.v1

# Validate token audience matches requested resource
allow if {
    token_audience_valid
    token_not_expired
    scope_appropriate
}

token_audience_valid if {
    token.aud == input.requested_resource
}

token_not_expired if {
    now := time.now_ns() / 1000000000
    token.exp > now
}

scope_appropriate if {
    required_scope := resource_scope_mapping[input.requested_resource]
    required_scope in token.scope
}

resource_scope_mapping := {
    "orders-api": "orders:read",
    "payments-api": "payments:process",
    "admin-api": "admin:write"
}
```

### Monitoring and Alerting Configuration

**Prometheus Alert Rules**

```yaml
groups:
  - name: identity-platform-alerts
    rules:
      - alert: SPIREServerDown
        expr: up{job="spire-server"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "SPIRE Server is down"
          description: "SPIRE Server has been down for more than 1 minute"
      
      - alert: HighAuthenticationFailureRate
        expr: rate(keycloak_failed_login_attempts_total[5m]) > 10
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High authentication failure rate"
          description: "Authentication failure rate is {{ $value }} per second"
      
      - alert: CertificateExpirationSoon
        expr: (spire_certificate_expiration_timestamp - time()) < 86400
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Certificate expiring soon"
          description: "Certificate for {{ $labels.spiffe_id }} expires in less than 24 hours"
```

**Grafana Dashboard Configuration**

```json
{
  "dashboard": {
    "id": null,
    "title": "ITL Identity Platform Overview",
    "tags": ["identity", "security"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Authentication Success Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(keycloak_successful_login_attempts_total[5m]) / rate(keycloak_total_login_attempts_total[5m]) * 100",
            "legendFormat": "Success Rate %"
          }
        ]
      },
      {
        "title": "Active SPIFFE Identities",
        "type": "graph",
        "targets": [
          {
            "expr": "spire_active_svids_total",
            "legendFormat": "Active SVIDs"
          }
        ]
      },
      {
        "title": "Teleport Sessions",
        "type": "graph",
        "targets": [
          {
            "expr": "teleport_active_sessions_total",
            "legendFormat": "Active Sessions"
          }
        ]
      }
    ]
  }
}
```

*This technology architecture provides the foundation for implementation planning. Proceed to Implementation Planning for detailed deployment and migration strategies.*