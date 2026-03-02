# Architecture Decisions

## Design Goals

This project was designed with four primary goals in mind:

1. **Automate response** — eliminate manual intervention for high-severity threats
2. **Preserve forensic evidence** — never destroy a compromised resource before capturing state
3. **Maintain audit integrity** — every action logged, encrypted, and tamper-evident
4. **Stay cost-conscious** — serverless-first architecture minimizes idle resource costs

These goals drove every service selection and design tradeoff documented below.

---

## Threat Model Assumptions

This pipeline was designed around the following assumed threat scenarios:

- **Compromised EC2 instance** — an attacker gains access to a running instance and begins lateral movement or data exfiltration
- **Cryptocurrency mining** — unauthorized workloads consuming compute resources detected by GuardDuty behavioral analysis
- **Unauthorized API access** — stolen or leaked IAM credentials used to make API calls from unexpected locations
- **Sensitive data exposure** — PII or confidential data accidentally stored in S3 and accessible beyond intended scope
- **Compliance drift** — security group rules modified to allow unrestricted SSH/RDP access

Out of scope for this design: DDoS attacks, supply chain compromises, and physical security threats.

---

## Why GuardDuty for threat detection?
GuardDuty uses machine learning to detect unauthorized access, compromised instances, and cryptocurrency mining without requiring agents or additional software. It analyzes VPC Flow Logs, CloudTrail, and DNS logs automatically. Alternative considered: manual CloudWatch log analysis — rejected because it requires custom rule writing and misses ML-based anomaly detection.

---

## Why multi-region CloudTrail?
A single-region trail would allow an attacker to operate undetected in other regions. Multi-region trail ensures comprehensive audit coverage and prevents attackers from disabling logging in one region while operating in another. Log file validation enabled to detect tampering.

---

## Why Lambda for incident response instead of manual process?
Lambda provides sub-second response times, scales automatically, and costs nothing when not executing. Manual response averages 4-8 hours for detection and containment. Lambda reduces MTTR to seconds. Serverless eliminates the need to manage response infrastructure.

---

## Isolation Strategy — Why isolate instead of terminate?
Terminating an instance destroys forensic evidence. Isolating by replacing the security group with an empty one preserves the instance state, memory, and disk for forensic investigation while preventing further network communication. EBS snapshots capture disk state before any remediation.

### Isolation steps in order:
1. EventBridge detects GuardDuty finding (severity >= 7)
2. Step Functions workflow triggered
3. Lambda creates empty security group in the instance VPC
4. Lambda replaces all instance security groups with the isolation group
5. Lambda snapshots all attached EBS volumes for forensics
6. DynamoDB logs the event with timestamp and instance details
7. SNS notifies the security team

This order ensures the instance is isolated before snapshots are taken, preventing any additional data from being written during forensic capture.

---

## Why Step Functions instead of a single Lambda?
A single Lambda function handling all response steps creates a monolithic, hard-to-maintain function with no visibility into which step failed. Step Functions provides visual workflow execution history, built-in error handling with catch blocks, retry logic, and clear audit trail of each step. Each step can be independently tested and updated.

---

## Failure Handling Strategy

Each Step Functions state has a `Catch` block that routes failures to `NotifyFailure` rather than silently failing. This ensures:

- The security team is always notified even when automation fails
- Failed executions are visible in Step Functions execution history
- CloudWatch logs capture Lambda error details for debugging
- DynamoDB still receives a log entry when possible

The design philosophy here is **fail loud, not silent** — a failed automated response that generates an alert is better than a failed response that goes unnoticed.

---

## Why Athena for log analysis instead of CloudWatch Insights?
Athena can query petabytes of S3 log data using standard SQL without ETL pipelines or data movement. CloudWatch Insights is limited to CloudWatch log groups. Athena queries CloudTrail logs directly from S3, making it cost-effective for historical threat hunting across large datasets.

---

## Why DynamoDB for audit trail?
DynamoDB is serverless, scales automatically, and provides single-digit millisecond read/write performance. Each security event is logged with a unique event_id and timestamp. Point-in-time recovery enabled for compliance. Alternative considered: RDS — rejected due to higher cost and operational overhead for an event logging use case.

---

## Why Security Hub with multiple standards?
Security Hub aggregates findings from GuardDuty, Macie, Inspector, and Config into a single dashboard. Enabling both AWS Foundational Security Best Practices (FSBP) and CIS v1.4.0 provides overlapping coverage — FSBP covers AWS-specific controls while CIS covers industry-standard benchmarks. Together they provide comprehensive compliance visibility.

---

## Why KMS customer-managed keys?
Customer-managed keys provide full control over key policies, rotation schedules, and access auditing. AWS-managed keys don't allow cross-service policy customization. CMKs are required to grant specific services (GuardDuty, CloudTrail) granular encryption permissions while blocking unauthorized access.

---

## Why EventBridge for automation trigger?
EventBridge natively integrates with GuardDuty findings and provides filtering by severity level. By filtering for severity >= 7 (high/critical), we avoid alert fatigue from low-severity findings while ensuring critical threats trigger immediate automated response. EventBridge decouples detection from response, making each component independently maintainable.

---

## Operational Guardrails

Several design decisions were made specifically to prevent the automation from causing more harm than the threat itself:

- **Severity threshold of 7** — only high and critical findings trigger automated isolation. Low/medium findings generate alerts only, requiring human review before action
- **Isolate, don't terminate** — automation never permanently destroys resources, preserving the ability to reverse the action if a false positive occurs
- **SNS notification at every step** — both success and failure paths notify the security team, ensuring a human is always in the loop
- **DynamoDB audit trail** — every automated action is logged with timestamp, event source, and account ID for post-incident review

---

## Scalability Considerations

This design was built for a single AWS account and region. To scale to a production multi-account environment:

- GuardDuty delegated administrator would centralize findings across all accounts
- EventBridge cross-account event forwarding would route findings to a central security account
- Step Functions and Lambda would live in the security account and assume cross-account roles to isolate instances in workload accounts
- Security Hub master account would aggregate findings from all member accounts
- DynamoDB global tables would provide multi-region audit trail replication

These were intentionally out of scope for this project but are documented in Project 05 (Multi-Account Governance).

---

## Limitations

Being transparent about the boundaries of this design:

- **No VPC deployed** — this project focuses on the detection and response pipeline. A real deployment would include VPC Flow Logs from a production VPC
- **Test execution only** — the Step Functions workflow was tested with a simulated EC2 instance ID. A real compromised instance was not used
- **Single region** — CloudTrail is multi-region but all response infrastructure is deployed in us-east-1 only
- **No ticketing integration** — a production SOC would integrate SNS with a ticketing system (PagerDuty, ServiceNow, Jira) for incident tracking
- **GuardDuty sample findings** — threat detection was validated using AWS's built-in sample findings generator, not real attack traffic
- **Lambda timeout** — current Lambda functions have default 3-second timeout which may be insufficient for instances with many attached volumes during snapshot