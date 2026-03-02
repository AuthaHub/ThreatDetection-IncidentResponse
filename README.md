# Project 03 — Automated Threat Detection & Incident Response Pipeline

[![AWS](https://img.shields.io/badge/AWS-Security-orange)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)](https://terraform.io)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

## Business Context

A Security Operations Center (SOC) automation pipeline for real-time threat detection and automated incident response. This project replaces manual security response with an automated detection, isolation, and forensic preservation pipeline — reducing mean time to respond (MTTR) from hours to seconds.

---

## Architecture Overview

![Architecture Diagram](architecture-diagram.png)

| Service | Role |
|---|---|
| GuardDuty | ML-based threat detection |
| Macie | Automated PII discovery in S3 |
| Security Hub | Centralized findings (FSBP + CIS v1.4.0) |
| CloudTrail | Multi-region audit logging with KMS |
| AWS Config | Compliance drift detection |
| EventBridge | Event-driven automation trigger |
| Lambda | Isolate EC2, snapshot EBS, log events |
| Step Functions | Multi-step remediation orchestration |
| DynamoDB | Security event audit trail |
| Athena + Glue | SQL threat hunting on CloudTrail logs |
| SNS + CloudWatch | Alerting and security metrics |
| KMS | Encryption for all data at rest |

---

## Incident Response Workflow

```
GuardDuty Finding (Severity ≥ 7)
           ↓
    EventBridge Rule
           ↓
  Step Functions Workflow
           ↓
IsolateEC2 → SnapshotEBS → LogEvent → NotifySOC
```

---

## Security Principles Applied

- **Least privilege IAM** — All roles scoped to minimum required permissions
- **Encryption everywhere** — KMS customer-managed keys for all data at rest
- **Immutable audit trail** — DynamoDB logging and CloudTrail log file validation enabled
- **Automated response** — MTTR reduced from hours to seconds via serverless automation
- **Defense in depth** — GuardDuty + Macie + Security Hub + Config layered detection

---

## Threat Scenarios Simulated

| Scenario | Method | Pipeline Response |
|---|---|---|
| EC2 cryptocurrency mining | GuardDuty sample finding (CryptoCurrency:EC2/BitcoinTool) | EventBridge triggered → Step Functions → IsolateEC2 → SnapshotEBS → NotifySOC |
| Unauthorized API calls | GuardDuty sample finding (UnauthorizedAccess:IAMUser) | CloudWatch alarm triggered → SNS alert to security team |
| Compromised EC2 instance | Step Functions test execution with simulated instance ID | Full workflow executed: isolate → snapshot → log → notify |
| S3 sensitive data exposure | Macie classification job scanning CloudTrail bucket | Automated daily scan for PII/sensitive data |
| CloudTrail log query | Athena SQL query against cloudtrail_logs table | Returned 10 real events including external IP addresses |

> **Note:** All threat scenarios were simulated using AWS GuardDuty's built-in sample findings generator and test payloads within a personal AWS account. No real infrastructure was compromised.

---

## Security Controls Mapping

| Control | AWS Service | Purpose |
|---|---|---|
| NIST IR-4 | Step Functions | Automated incident handling and response |
| NIST IR-5 | DynamoDB | Security event tracking and audit trail |
| NIST IR-6 | SNS | Incident reporting and team notification |
| NIST AU-2 | CloudTrail | Audit event logging across all regions |
| NIST AU-9 | KMS + S3 | Protection of audit logs at rest |
| NIST SI-4 | GuardDuty | System monitoring and threat detection |
| NIST SI-7 | AWS Config | Software and information integrity checks |
| NIST RA-5 | Macie | Vulnerability and sensitive data scanning |
| PCI DSS 10.x | CloudTrail + Athena | Audit logging and log analysis |
| PCI DSS 11.4 | GuardDuty + Security Hub | Intrusion detection and centralized findings |
| PCI DSS 12.10 | Step Functions + Lambda | Automated incident response plan |
| CIS v1.4.0 | Security Hub | Benchmark compliance monitoring |
| CIS 3.x | CloudWatch Alarms | Monitoring and alerting on API activity |

---

## Prerequisites

- AWS CLI installed and configured (`aws configure`)
- Terraform >= 1.5.0 installed
- AWS account with appropriate IAM permissions
- An email address for SNS security alerts

---

## Deployment

### Step 1 — Clone the repository

```bash
git clone https://github.com/AuthaHub/Project-03-ThreatDetection-IncidentResponse.git
cd Project-03-ThreatDetection-IncidentResponse
```

### Step 2 — Configure variables

Copy the example file and edit with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region   = "us-east-1"
project_name = "p03-threat-detection"
environment  = "dev"
alert_email  = "your-email@example.com"
```

### Step 3 — Initialize Terraform

```bash
terraform init
```

### Step 4 — Review the plan

```bash
terraform plan -var-file="terraform.tfvars"
```

### Step 5 — Deploy

```bash
terraform apply -var-file="terraform.tfvars"
```

### Module Deployment Order

Terraform automatically handles dependencies in this order:

1. `kms` — KMS key created first, all other modules depend on it
2. `s3` — S3 bucket for CloudTrail logs
3. `cloudtrail` — Multi-region trail
4. `guardduty` — Threat detection enabled
5. `macie` — PII scanning enabled
6. `security_hub` — Centralized findings
7. `sns` — Alert topic and email subscription
8. `cloudwatch` — Alarms and log groups
9. `dynamodb` — Audit trail table
10. `lambda` — Incident response functions
11. `eventbridge` — GuardDuty finding triggers
12. `step_functions` — Remediation workflow
13. `athena` — Log analysis workgroup and Glue catalog
14. `config` — Compliance rules and recorder

---

## Validation

After deployment, confirm each component is working:

- **GuardDuty** → Settings → Generate sample findings → check Findings page
- **Macie** → Summary page → confirm enabled and scanning
- **Security Hub** → Security standards → confirm FSBP and CIS v1.4.0 enabled
- **Step Functions** → Start execution with test payload → confirm workflow triggers
- **Athena** → Query editor → run SELECT against cloudtrail_logs table
- **CloudWatch** → Alarms → confirm root-usage and unauthorized-api alarms exist
- **SNS** → Confirm subscription email received and confirmed

---

## Cleanup

> **Important:** Always destroy resources same day to avoid unexpected charges from Config and GuardDuty.

### Step 1 — Empty S3 buckets

```bash
# Empty CloudTrail bucket
aws s3 rm s3://$(terraform output -raw cloudtrail_bucket_name) --recursive

# Empty Athena results bucket
aws s3 rm s3://$(terraform output -raw athena_results_bucket_name) --recursive
```

### Step 2 — Destroy all resources

```bash
terraform destroy -var-file="terraform.tfvars"
```

### Step 3 — Verify cleanup

```bash
terraform state list
```

An empty response confirms all resources are destroyed.

---

## Cost Analysis

| Service | Estimated Cost |
|---|---|
| GuardDuty | Free for first 30 days, then ~$4.50/month |
| AWS Config | ~$0.003 per rule evaluation (~$2-3/day) |
| Lambda | Within free tier for this project |
| DynamoDB | Within free tier for this project |
| SNS | Within free tier for this project |
| Athena | ~$0.005 per query (pennies) |
| KMS | $1/month per key |
| CloudTrail | Free (first trail), S3 storage ~$0.023/GB |

**Total estimated cost:** ~$0.50-$1.00 per day if destroyed same day

---

## Project Structure

```
Project-03-ThreatDetection-IncidentResponse/
├── modules/
│   ├── athena/              # Athena workgroup and Glue catalog for log analysis
│   ├── cloudtrail/          # Multi-region CloudTrail with log file validation
│   ├── cloudwatch/          # Log groups and alarms for security monitoring
│   ├── config/              # AWS Config rules for compliance drift detection
│   ├── dynamodb/            # Security event audit trail table
│   ├── eventbridge/         # Event-driven automation rules
│   ├── guardduty/           # GuardDuty detector configuration
│   ├── kms/                 # Customer-managed encryption keys
│   ├── lambda/              # Incident response functions
│   ├── macie/               # Macie sensitive data discovery
│   ├── s3/                  # S3 buckets with encryption and versioning
│   ├── security-hub/        # Security Hub with FSBP and CIS standards
│   ├── sns/                 # SNS topics and email subscriptions
│   └── step-functions/      # Orchestration workflows
├── docs/
│   ├── architecture-decisions.md
│   ├── architecture-diagram.png
│   ├── build-log.md
│   └── cost-and-cleanup.md
├── screenshots/
├── main.tf                  # Root module configuration
├── variables.tf             # Variable definitions
├── outputs.tf               # Output values
├── versions.tf              # Provider version constraints
├── terraform.tfvars.example # Example configuration file
├── .gitignore
└── README.md
```

---

## Additional Documentation

- [Architecture Decisions](docs/architecture-decisions.md) — Design choices and technical rationale
- [Build Log](docs/build-log.md) — Detailed implementation timeline and challenges
- [Cost & Cleanup](docs/cost-and-cleanup.md) — Cost breakdown and cleanup procedures

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

Built as part of a portfolio demonstrating AWS security automation and Infrastructure as Code best practices.