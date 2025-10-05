# Compliance Mapping

This document maps the ITL Identity Platform architecture to various compliance frameworks and regulatory requirements.

## ISO 27001/27002 Information Security Controls

### A.9 Access Control

**A.9.1 Business Requirements of Access Control**

| Control | Description | Implementation | Evidence |
|---------|-------------|----------------|-----------|
| A.9.1.1 | Access control policy | Keycloak realm policies, OPA admission control | Policy documents, configuration files |
| A.9.1.2 | Access to networks and network services | Network policies, service mesh mTLS | Network configuration, traffic logs |

**A.9.2 User Access Management**

| Control | Description | Implementation | Evidence |
|---------|-------------|----------------|-----------|
| A.9.2.1 | User registration and de-registration | Keycloak user lifecycle management | User provisioning logs, audit trails |
| A.9.2.2 | User access provisioning | JIT access via Teleport, token exchange | Access request logs, approval workflows |
| A.9.2.3 | Management of privileged access rights | PIM workflows, time-bound elevation | Privileged access logs, approval records |
| A.9.2.4 | Management of secret authentication information | SPIFFE certificates, automatic rotation | Certificate lifecycle logs, rotation schedules |
| A.9.2.5 | Review of user access rights | Automated access reviews, quarterly audits | Access review reports, compliance dashboards |
| A.9.2.6 | Removal or adjustment of access rights | Automated deprovisioning, access revocation | Account termination logs, access change records |

**A.9.3 User Responsibilities**

| Control | Description | Implementation | Evidence |
|---------|-------------|----------------|-----------|
| A.9.3.1 | Use of secret authentication information | MFA enforcement, secure key storage | Authentication logs, MFA usage statistics |

**A.9.4 System and Application Access Control**

| Control | Description | Implementation | Evidence |
|---------|-------------|----------------|-----------|
| A.9.4.1 | Information access restriction | RBAC, API-level authorization | Permission matrices, access control lists |
| A.9.4.2 | Secure log-on procedures | OIDC/SAML authentication, MFA | Authentication flow logs, security events |
| A.9.4.3 | Password management system | Keycloak password policies, complexity rules | Password policy configuration, compliance reports |
| A.9.4.4 | Use of privileged utility programs | Teleport session recording, command auditing | Session recordings, command logs |
| A.9.4.5 | Access control to program source code | GitOps access controls, code review processes | Repository access logs, PR approval records |

### A.10 Cryptography

| Control | Description | Implementation | Evidence |
|---------|-------------|----------------|-----------|
| A.10.1.1 | Policy on the use of cryptographic controls | TLS 1.3, certificate-based authentication | Cryptographic policy, certificate standards |
| A.10.1.2 | Key management | SPIRE CA, automated certificate rotation | Key lifecycle management, rotation logs |

### A.12 Operations Security

| Control | Description | Implementation | Evidence |
|---------|-------------|----------------|-----------|
| A.12.4.1 | Event logging | Centralized logging, audit trails | Log aggregation, security event monitoring |
| A.12.4.2 | Protection of log information | Immutable logging, access controls | Log integrity verification, access records |
| A.12.4.3 | Administrator and operator logs | Privileged access logging, session recording | Administrative activity logs, session archives |
| A.12.4.4 | Clock synchronization | NTP synchronization across clusters | Time synchronization logs, drift monitoring |

## NIST Cybersecurity Framework

### Identify (ID)

**ID.AM - Asset Management**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| ID.AM-1 | Kubernetes resource inventory, application catalog | Resource discovery, asset registers |
| ID.AM-2 | SPIFFE identity mapping, service dependencies | Service mesh topology, dependency graphs |
| ID.AM-3 | Network segmentation, trust boundaries | Network policies, zone configurations |

**ID.GV - Governance**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| ID.GV-1 | Security policies, architecture governance | Policy documents, ARB decisions |
| ID.GV-3 | Legal and regulatory requirements mapping | Compliance matrices, control implementations |
| ID.GV-4 | Architecture Review Board, security oversight | Governance meeting minutes, review records |

### Protect (PR)

**PR.AC - Access Control**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| PR.AC-1 | SPIFFE workload identity, certificate lifecycle | Identity attestation, certificate issuance logs |
| PR.AC-3 | RBAC, API gateway authentication | Permission models, access control matrices |
| PR.AC-4 | Least privilege, JIT access elevation | Access request workflows, privilege reviews |
| PR.AC-5 | Network segmentation, micro-segmentation | Network policies, traffic analysis |
| PR.AC-6 | Multi-factor authentication, strong authentication | MFA enrollment, authentication metrics |

**PR.AT - Awareness and Training**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| PR.AT-1 | Security awareness program, platform training | Training records, competency assessments |
| PR.AT-2 | Privileged user training, security responsibilities | Specialized training, role-based education |

**PR.DS - Data Security**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| PR.DS-1 | Data classification, protection requirements | Data classification scheme, protection controls |
| PR.DS-2 | Data in transit protection (TLS 1.3, mTLS) | Encryption configuration, traffic analysis |
| PR.DS-5 | Data leak prevention, API security | API security controls, data loss prevention |

**PR.IP - Information Protection Processes**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| PR.IP-1 | Security configuration baselines | Configuration standards, compliance scanning |
| PR.IP-3 | Configuration change management | GitOps workflows, change approval processes |
| PR.IP-4 | Backup and recovery procedures | Backup schedules, recovery testing |

**PR.MA - Maintenance**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| PR.MA-1 | Maintenance procedures, change controls | Maintenance schedules, approval workflows |
| PR.MA-2 | Remote maintenance security | Secure access procedures, session monitoring |

**PR.PT - Protective Technology**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| PR.PT-1 | Audit logging, security monitoring | Log analysis, security dashboards |
| PR.PT-3 | Least functionality principle | Minimal deployments, service hardening |
| PR.PT-4 | Secure communications | Encryption standards, secure protocols |

### Detect (DE)

**DE.AE - Anomalies and Events**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| DE.AE-1 | Security event baselines | Baseline measurements, anomaly detection |
| DE.AE-2 | Event analysis, correlation | SIEM integration, event correlation |
| DE.AE-3 | Event data aggregation | Centralized logging, data aggregation |
| DE.AE-5 | Incident alert thresholds | Alert configuration, escalation procedures |

**DE.CM - Security Continuous Monitoring**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| DE.CM-1 | Network monitoring, traffic analysis | Network monitoring tools, traffic baselines |
| DE.CM-3 | Personnel activity monitoring | User behavior analytics, activity monitoring |
| DE.CM-4 | Malicious code detection | Security scanning, malware detection |
| DE.CM-7 | Vulnerability monitoring | Vulnerability scanning, patch management |
| DE.CM-8 | External threat intelligence | Threat feeds, intelligence integration |

**DE.DP - Detection Processes**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| DE.DP-1 | Detection roles and responsibilities | Security team structure, role definitions |
| DE.DP-2 | Detection activities compliance | Detection procedures, compliance validation |
| DE.DP-3 | Detection testing procedures | Detection testing, validation exercises |
| DE.DP-4 | Event detection information communication | Alert procedures, notification systems |
| DE.DP-5 | Detection process improvement | Process reviews, improvement initiatives |

### Respond (RS)

**RS.RP - Response Planning**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| RS.RP-1 | Incident response plan | Response procedures, escalation plans |

**RS.CO - Communications**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| RS.CO-2 | Incident reporting criteria | Incident classification, reporting procedures |
| RS.CO-3 | Stakeholder information sharing | Communication plans, stakeholder notifications |

**RS.AN - Analysis**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| RS.AN-1 | Investigation procedures | Forensic procedures, evidence collection |
| RS.AN-2 | Impact analysis procedures | Impact assessment, business continuity |

**RS.MI - Mitigation**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| RS.MI-1 | Containment procedures | Incident containment, isolation procedures |
| RS.MI-2 | Mitigation activities | Response actions, remediation procedures |
| RS.MI-3 | Vulnerability mitigation | Vulnerability response, patch management |

**RS.IM - Improvements**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| RS.IM-1 | Response plan updates | Plan maintenance, lessons learned |
| RS.IM-2 | Response strategy updates | Strategy evolution, improvement implementation |

### Recover (RC)

**RC.RP - Recovery Planning**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| RC.RP-1 | Recovery plan execution | Recovery procedures, execution documentation |

**RC.IM - Improvements**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| RC.IM-1 | Recovery plan updates | Plan maintenance, improvement implementation |
| RC.IM-2 | Recovery strategy updates | Strategy evolution, lesson integration |

**RC.CO - Communications**

| Subcategory | Implementation | Evidence |
|-------------|----------------|-----------|
| RC.CO-2 | Recovery plan status communication | Status reporting, stakeholder updates |
| RC.CO-3 | Public updates and information sharing | Public communications, transparency reporting |

## SOX Compliance (Sarbanes-Oxley Act)

### IT General Controls (ITGC)

**Access Controls**

| Requirement | Implementation | Evidence |
|-------------|----------------|-----------|
| Logical access controls | RBAC, principle of least privilege | Access control matrices, permission reviews |
| Segregation of duties | Role separation, approval workflows | Role definitions, workflow documentation |
| User access management | Automated provisioning/deprovisioning | User lifecycle management, access logs |
| Privileged access management | JIT elevation, approval processes | PIM workflows, privileged access logs |

**Change Management**

| Requirement | Implementation | Evidence |
|-------------|----------------|-----------|
| Change approval process | GitOps workflows, ARB approval | Change records, approval documentation |
| Testing procedures | Automated testing, validation | Test results, validation reports |
| Change documentation | ADRs, configuration management | Change documentation, version control |
| Emergency change procedures | Emergency access, post-review | Emergency procedures, review records |

**Computer Operations**

| Requirement | Implementation | Evidence |
|-------------|----------------|-----------|
| Job scheduling and monitoring | Kubernetes jobs, monitoring | Job schedules, execution logs |
| Backup and recovery | Automated backups, DR procedures | Backup logs, recovery testing |
| Incident management | Incident response, escalation | Incident records, response documentation |

**Information Security**

| Requirement | Implementation | Evidence |
|-------------|----------------|-----------|
| Security policies and procedures | Security framework, policies | Policy documents, procedure guides |
| Vulnerability management | Security scanning, patch management | Vulnerability reports, patch records |
| Security monitoring | SIEM, security dashboards | Security events, monitoring reports |
| Data protection | Encryption, access controls | Encryption configuration, protection measures |

## GDPR (General Data Protection Regulation)

### Data Protection Principles

| Principle | Implementation | Evidence |
|-----------|----------------|-----------|
| Lawfulness, fairness, transparency | Privacy notices, consent management | Privacy policies, consent records |
| Purpose limitation | Data minimization, purpose binding | Data classification, usage policies |
| Data minimization | Minimal data collection, retention policies | Data inventories, retention schedules |
| Accuracy | Data validation, correction procedures | Data quality processes, correction logs |
| Storage limitation | Automated deletion, retention policies | Retention enforcement, deletion logs |
| Integrity and confidentiality | Encryption, access controls | Security measures, protection controls |
| Accountability | Privacy governance, documentation | Privacy assessments, compliance records |

### Data Subject Rights

| Right | Implementation | Evidence |
|-------|----------------|-----------|
| Right to be informed | Privacy notices, transparency | Privacy communications, notice delivery |
| Right of access | Data export, subject access | Access request procedures, response logs |
| Right to rectification | Data correction procedures | Correction processes, update records |
| Right to erasure | Data deletion, anonymization | Deletion procedures, erasure logs |
| Right to restrict processing | Processing controls, temporary suspension | Processing restrictions, control records |
| Right to data portability | Data export, format standards | Export procedures, format specifications |
| Right to object | Opt-out mechanisms, processing controls | Objection procedures, processing stops |

### Technical and Organizational Measures

| Measure | Implementation | Evidence |
|---------|----------------|-----------|
| Pseudonymization | Data tokenization, anonymization | Pseudonymization techniques, implementation |
| Encryption | TLS 1.3, certificate-based encryption | Encryption standards, key management |
| Confidentiality | Access controls, data classification | Access procedures, classification schemes |
| Integrity | Data validation, integrity checking | Integrity controls, validation procedures |
| Availability | High availability, disaster recovery | Availability measures, recovery procedures |
| Resilience | Fault tolerance, redundancy | Resilience testing, redundancy implementation |

---

*This compliance mapping provides the foundation for demonstrating regulatory compliance and implementing appropriate controls within the ITL Identity Platform.*