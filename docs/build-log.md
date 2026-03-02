# Build Log

## Project 03 — Automated Threat Detection & Incident Response Pipeline

---

## Phase 0 — Project Setup
**Date:** February 21, 2026

Without a clean folder structure, consistent naming, and git connected to GitHub from the start, every subsequent phase would carry technical debt in the commit history and file organization. This phase set the foundation everything else was built on.

**Resources deployed:** Folder structure, Terraform root files, git initialization, GitHub remote connection

**Issues encountered:**
- PowerShell attempted to run the folder tree diagram (├── characters) as commands — harmless, files were already created correctly

**Improvements for Next Iteration:**
- Add a `.gitignore` file as the very first step before any terraform init
- Add `backend` block to `versions.tf` for remote state in S3 + DynamoDB lock from the start
- Add variable validation blocks to `variables.tf` to catch bad inputs early

---

## Phase 1 — Core Logging & Visibility
**Date:** February 21, 2026

This phase established the immutable audit foundation required for detection, forensic analysis, and compliance validation. Without CloudTrail and KMS in place first, no other security service would have a secure place to send its findings.

**Resources deployed:** KMS key, KMS alias, S3 bucket (CloudTrail logs), S3 versioning, S3 encryption, S3 public access block, S3 bucket policy, CloudTrail multi-region trail

**Issues encountered:**
- `.terraform/` provider binary (685MB) committed to git, exceeding GitHub's 100MB file size limit
- Fix: added `.terraform/`, `terraform.tfstate`, and `terraform.tfstate.backup` to `.gitignore`, removed cached files with `git rm -r --cached .terraform`, rewrote git history with `git filter-branch --force`, force pushed to GitHub

**Improvements for Next Iteration:**
- Add `lifecycle { prevent_destroy = true }` to KMS key to prevent accidental deletion
- Add `lifecycle { prevent_destroy = true }` to CloudTrail S3 bucket
- Add backend remote state (S3 + DynamoDB lock) for team collaboration safety

---

## Phase 2 — Threat Detection
**Date:** February 21, 2026

This phase activated the detection layer of the SOC pipeline. GuardDuty, Macie, and Security Hub together provide layered visibility — behavioral anomaly detection, sensitive data discovery, and centralized findings aggregation. Without this phase, threats would occur with no visibility.

**Resources deployed:** GuardDuty detector, GuardDuty publishing destination, Macie account, Macie classification job, Security Hub account, Security Hub FSBP standard, Security Hub CIS v1.4.0 standard

**Issues encountered:**
1. KMS key policy missing GuardDuty principal — Fix: added GuardDuty service principal to KMS key policy Statement array
2. S3 bucket policy missing GuardDuty permissions — Fix: added AWSGuardDutyWrite and AWSGuardDutyCheck statements to S3 bucket policy
3. Security Hub CIS standard ARN version mismatch — Fix: updated ARN from v1.2.0 to v1.4.0 (v1.2.0 no longer valid)
4. Macie service-linked role propagation delay — Fix: re-ran terraform apply after waiting a few minutes for role to propagate

**Validation:**
- GuardDuty sample findings generated successfully
- Macie summary page confirmed enabled with 4 buckets detected
- Security Hub showing both standards enabled

**Improvements for Next Iteration:**
- Add GuardDuty threat intelligence feeds for custom threat indicators
- Add Inspector2 for EC2 vulnerability scanning
- Add retry logic or `depends_on` delay for Macie classification job to handle service-linked role propagation

---

## Phase 3 — Alerting & Notification
**Date:** February 21, 2026

Detection without notification is useless. This phase connected the detection layer to the human response layer, ensuring every critical security event generates a real-time alert to the security team with no manual monitoring required.

**Resources deployed:** SNS topic (security-alerts), SNS email subscription, CloudWatch log group, CloudWatch metric filters (root usage, unauthorized API), CloudWatch alarms

**Issues encountered:**
- SNS email subscription had incorrect email address (`your-ivyleagcompliance@gmail.com`) — Fix: corrected email in terraform.tfvars to `ivyleagcompliance@gmail.com`, re-ran apply, confirmed subscription via email

**Validation:**
- SNS topic created and subscription confirmed via email
- CloudWatch alarms showing "Insufficient data" (expected — no log data flowing yet)

**Improvements for Next Iteration:**
- Add CloudWatch Dashboard for visual security metrics
- Add additional metric filters for console sign-ins without MFA
- Store alert email in AWS Secrets Manager instead of tfvars

---

## Phase 4 — Automated Incident Response
**Date:** February 21, 2026

This phase built the automated response capability — the core differentiator of this project. Lambda functions replace manual analyst intervention for high-severity findings, reducing MTTR from hours to seconds. DynamoDB provides the tamper-evident audit trail required for compliance reporting.

**Resources deployed:** DynamoDB table, IAM role (Lambda), IAM policy (Lambda), Lambda functions (isolate-ec2, snapshot-ebs, log-event), EventBridge rule, EventBridge targets (x3), Lambda permissions (x3)

**Issues encountered:**
- None — clean deploy on first apply

**Validation:**
- All three Lambda functions visible in console (Python 3.11)
- EventBridge rule enabled and targeting default event bus
- DynamoDB table active with correct partition and sort keys

**Improvements for Next Iteration:**
- Increase Lambda timeout from default 3 seconds for instances with many EBS volumes
- Add Lambda dead letter queue (DLQ) for failed invocations
- Add Lambda environment variable encryption using KMS
- Add DynamoDB TTL for automatic event expiration after retention period

---

## Phase 5 — Orchestration
**Date:** February 21, 2026

Individual Lambda functions executing in isolation are hard to monitor and maintain. This phase tied all response actions into a single coordinated workflow with visual execution history, built-in error handling, and a clear audit trail of every step taken during an incident.

**Resources deployed:** IAM role (Step Functions), IAM policy (Step Functions), Step Functions state machine

**Issues encountered:**
- Step Functions resource code accidentally pasted into root `main.tf` instead of `modules\step-functions\main.tf` — Fix: cleared root `main.tf` to contain only module blocks, confirmed resource code was correctly in the module file, re-ran apply
- After fix, terraform showed "no changes" but state machine was not in AWS — Fix: confirmed root `main.tf` was correct, re-ran terraform init and apply, 3 resources added successfully

**Validation:**
- State machine visible in console, status Active
- Test execution run with simulated EC2 instance ID
- Execution failed as expected — confirmed error handling routed correctly to NotifyFailure path
- Graph view showed complete workflow: IsolateEC2 → caught error → NotifyFailure → End

**Improvements for Next Iteration:**
- Add Step Functions Express workflow for high-volume, low-latency execution
- Add X-Ray tracing for detailed execution visibility
- Add wait state between IsolateEC2 and SnapshotEBS to confirm isolation before snapshotting

---

## Phase 6 — Log Analysis
**Date:** February 21, 2026

Detection and response are only part of the picture. This phase enabled threat hunting and forensic investigation by transforming the S3 CloudTrail bucket into a queryable security data lake — allowing analysts to run SQL queries across months of audit history without moving or transforming data.

**Resources deployed:** S3 bucket (Athena results), S3 public access block, S3 encryption, Athena workgroup, Glue catalog database, Glue catalog table (cloudtrail_logs)

**Issues encountered:**
- Athena module accidentally added to `modules\step-functions\main.tf` instead of root `main.tf` — Fix: removed module block from step-functions file, added correctly to root `main.tf`

**Validation:**
- Athena workgroup active in console
- Glue database and cloudtrail_logs table created
- SQL query executed successfully returning 10 real CloudTrail events including external IP addresses

**Improvements for Next Iteration:**
- Add saved Athena queries for common threat hunting scenarios
- Add Glue crawler for automatic schema detection
- Add Athena named queries as Terraform resources for documentation

---

## Phase 7 — Compliance
**Date:** February 21, 2026

Building security controls is only valuable if you can prove they stay in place over time. This phase added continuous compliance monitoring to detect and report configuration drift — turning one-time security checks into ongoing automated enforcement.

**Resources deployed:** IAM role (Config), IAM policy attachment, Config recorder, Config delivery channel, S3 bucket (Config snapshots), S3 public access block, S3 bucket policy, Config recorder status, Config rules (restricted-ssh, restricted-rdp, s3-public-access, cloudtrail-enabled)

**Issues encountered:**
- None — clean deploy on first apply

**Validation:**
- Config recorder showing "Recording is on"
- All four Config rules visible in console
- S3 bucket and SNS topic linked to delivery channel

**Improvements for Next Iteration:**
- Add Config auto-remediation SSM documents for restricted-ssh and restricted-rdp rules
- Add additional rules for encrypted EBS volumes and MFA on root account
- Add Config aggregator for multi-account visibility

---

## Teardown
**Date:** February 21, 2026

**Issues encountered:**
1. Athena workgroup not empty during terraform destroy — Athena resources require S3 bucket cleanup prior to destroy due to dependency enforcement in AWS APIs. Fix: ran `aws s3 rm s3://p03-threat-detection-dev-athena-results-<account-id> --recursive` to empty results bucket, re-ran destroy
2. Athena workgroup still blocked after S3 empty — Fix: manually deleted workgroup from AWS Console (Actions → Delete), re-ran terraform destroy successfully

**Final state:** `terraform state list` returned empty — all resources destroyed confirmed

---

## Lessons Learned

1. Always add `.terraform/` and `terraform.tfstate` to `.gitignore` before first commit
2. Run `terraform init` after adding any new module to root `main.tf`
3. Root `main.tf` should contain only module blocks — resource definitions belong in module files
4. KMS key policies must explicitly grant permissions to each AWS service that needs to use the key
5. S3 bucket policies must be updated when adding new services that write to the bucket
6. Check AWS service ARN versions before deploying — Security Hub CIS standard moved from v1.2.0 to v1.4.0
7. Athena workgroup must be emptied before terraform destroy can delete it
8. Macie service-linked roles take a few minutes to propagate — retry apply if classification job fails immediately after enabling Macie
9. Service-linked roles introduce timing dependencies that may require retry logic or apply sequencing in production pipelines
10. Always validate actual AWS console state when Terraform reports "no changes" — state drift can occur when resources are partially created or manually modified outside of Terraform

---

## What I Would Improve Next Iteration

- Convert root modules into environment-specific Terraform workspaces (dev/staging/prod)
- Add variable validation blocks to catch invalid inputs before apply
- Add `lifecycle { prevent_destroy = true }` on KMS key and CloudTrail S3 bucket
- Add backend remote state using S3 + DynamoDB locking for team safety
- Add Lambda dead letter queues for failed invocations
- Add retry logic for service-linked role propagation delays
- Add Step Functions X-Ray tracing for detailed execution visibility
- Add Config auto-remediation SSM documents for security group rules
- Add saved Athena named queries for common threat hunting scenarios
- Integrate SNS with a ticketing system (PagerDuty or Jira) for incident tracking