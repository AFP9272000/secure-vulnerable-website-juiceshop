## Quickstart

1. Clone this repo and fill in `terraform.tfvars` (see `variables.tf` for required variables).
2. Run `terraform init` and `terraform apply`.
3. IMPORTANT: After Terraform finishes, follow the manual step below to attach the WAF WebACL to CloudFront.





#  Vulnerable OWASP Juice Shop Behind CloudFront + WAF (Terraform)

**Goal:** Deploy the intentionally vulnerable OWASP Juice Shop web app on AWS, secure it behind CloudFront with TLS + WAF, and restrict origin access so that only CloudFront can reach the EC2 instance.  

This project demonstrates how to take an insecure app and wrap it with AWS-native defenses using IAC (Terraform).

---

## What This deploys:
- **EC2 Instance (Amazon Linux 2023)**  
  - Runs OWASP Juice Shop in Docker on port `3000`  
  - Root volume expanded to 20 GiB to accommodate Docker image  
- **Security Group**  
  - SSH (22) only from my IP  
  - App traffic (3000) only from **CloudFront origin-facing prefix list**  
- **CloudFront Distribution**  
  - HTTPS enforced (HTTP -> HTTPS redirect)  
  - Standard logging -> S3 log bucket  
  - Custom response headers (HSTS, X-Content-Type-Options, etc.)  
- **AWS WAF v2 (Global)**  
  - Managed rule sets (Common, IP reputation, bad bots)  
  - Rate-based rule to throttle abusive requests  
- **Monitoring & Alerts**  
  - CloudWatch alarm on `CPUUtilization >= 70%` (2×5m)  
  - Alarm notifications via SNS -> email  
- **S3 Log Bucket**  
  - Private, versioned, lifecycle policy to Glacier  
  - Stores CloudFront logs (+ optionally S3 server access logs)

## IMPORTANT: Manual Step: Attach WAF to CloudFront
Due to a current AWS/Terraform limitation, associating a WAFv2 WebACL with a CloudFront distribution cannot always be automated reliably.  
After running `terraform apply`, attach the WebACL to the distribution via the AWS Console.  

This step is documented here to show awareness of the limitation and to ensure a secure final configuration.


---

## Architecture:

```mermaid
flowchart LR
    subgraph Internet
        U[User Browser]
    end

    U -->|HTTPS| CF[CloudFront Distribution]

    %% WAF at the edge
    WAF[[AWS WAF v2\nManaged Rules + Rate Limit]]
    CF --- WAF

    %% Logs
    CF -->|Standard Logs| S3L[(S3 Logs Bucket)]

    %% Origin path
    CF -->|HTTP :3000\n(origin-facing only)| EC2[(EC2: Juice Shop\nDocker on :3000)]

    %% Security Group
    EC2 --- SG{{SG:\n22 from My IP\n3000 from CloudFront prefix list}}

    %% Observability
    EC2 --> CW[CloudWatch Metrics]
    CW --> ALRM[[CPU ≥ 70% Alarm\n-> SNS Email]]
