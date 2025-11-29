# Secure Vulnerable Web Application with DevSecOps Pipeline

[![Terraform](https://img.shields.io/badge/Terraform-1.6.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)

> **Production-grade DevSecOps implementation** deploying OWASP Juice Shop on AWS with automated security scanning, zero-credential authentication, and infrastructure as code.

---

## What Makes This Different

This project is more than a Terraform deployment—it is a **complete DevSecOps pipeline** including:

* **Zero-credential security** via OIDC (no AWS keys stored)
* **Automated security scanning** with 4 tools (Checkov, TFLint, Trivy, tfsec)
* **Multi-layer defense** (CloudFront → WAF → Security Groups → Docker)
* **Infrastructure drift detection** with weekly scans
* **CI/CD with approval gates** for production
* **Remote state management** with S3 + DynamoDB locking

**Challenge:** Securely deploy an intentionally vulnerable application while implementing enterprise-grade DevOps practices.

**Solution:** AWS-native security layers plus automated scanning catching vulnerabilities before production.

---

## Architecture

```
Internet Users (HTTPS)
        ↓
   CloudFront CDN
   • TLS Termination
   • Security Headers
        ↓
      AWS WAF
   • OWASP Top 10 Rules
   • Rate Limiting (1000 req/5min)
   • IP Reputation Filtering
        ↓
   Security Group
   • CloudFront Prefix List Only
   • Port 3000 Locked Down
        ↓
   EC2 Instance (AL2023)
   • Docker: Juice Shop Container
   • CloudWatch Monitoring
   • 20GB Encrypted EBS
        ↓
   Monitoring & Logs
   • S3 Logs Bucket (Encrypted, Versioned)
   • CloudWatch Alarms (CPU ≥70%)
   • SNS Email Alerts
```

**Security Layers:**

1. **Edge:** CloudFront with custom security headers (HSTS, CSP, X-Frame-Options)
2. **Application Firewall:** AWS WAF with managed rules + rate limiting
3. **Network:** Security group restricting origin access to CloudFront only
4. **Container:** Docker isolation with version-pinned image

---

## DevSecOps Pipeline

### Automated Security Scanning

Every commit triggers:

| Scanner | Purpose                  | Rules          |
| ------- | ------------------------ | -------------- |
| Checkov | Policy violations        | 750+ checks    |
| TFLint  | Terraform best practices | AWS-specific   |
| Trivy   | CVE detection            | CRITICAL/HIGH  |
| tfsec   | AWS misconfigurations    | CIS benchmarks |

Results are automatically posted to GitHub Security tab in SARIF format.

### CI/CD Workflow

```
Git Push → Security Scans → Terraform Validate → Plan → Manual Approval → Apply
                ↓                                          ↓
         Fail if CRITICAL                          Environment Gate
```

**Key Features:**

* Manual approval for production deployments
* Automatic PR plan comments
* Weekly drift detection with issue creation
* Terraform state in S3 with DynamoDB locking
* Average deployment: 8–12 minutes

### OIDC Authentication (Zero Credentials)

**Traditional approach (insecure):**

```yaml
aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
```

**Secure approach in this project:**

```yaml
role-to-assume: ${{ secrets.AWS_ROLE_ARN }}  # Temporary tokens (1 hour)
```

**Benefits:**

* No credential rotation needed
* Full CloudTrail audit trail
* Automatic token expiration
* Repo-specific permissions

---

## Quick Start

### Prerequisites

* AWS account with admin access
* Terraform >= 1.6.0
* EC2 key pair for SSH
* Your public IP address

### 1. Set Up AWS OIDC (One-Time)

**Create OIDC Provider:**

```bash
# AWS Console → IAM → Identity Providers → Add Provider
# Provider URL: https://token.actions.githubusercontent.com
# Audience: sts.amazonaws.com
```

**Create IAM Role:**

* Trust policy: GitHub repo
* Attach policies: EC2, S3, CloudFront, WAF, CloudWatch, SNS
* Save the role ARN for GitHub secrets

### 2. Configure GitHub Secrets

Settings → Secrets and variables → Actions

| Secret                  | Value              | Example                                      |
| ----------------------- | ------------------ | -------------------------------------------- |
| AWS_ROLE_ARN            | IAM role ARN       | arn:aws:iam::123456789:role/github-oidc-role |
| AWS_REGION              | AWS region         | us-east-2                                    |
| TF_VAR_ALERT_EMAIL      | Email for alerts   | you@example.com                              |
| TF_VAR_KEY_NAME         | EC2 key pair       | my-keypair                                   |
| TF_VAR_LOGS_BUCKET_NAME | Unique bucket name | mycompany-juice-logs-123456                  |
| TF_VAR_MY_IP_CIDR       | IP for SSH         | 203.0.113.45/32                              |

### 3. Deploy via GitHub Actions

```bash
git clone https://github.com/AFP9272000/secure-vulnerable-website-juiceshop.git
cd secure-vulnerable-website-juiceshop

git commit --allow-empty -m "Trigger deployment"
git push origin main
```

**Pipeline Steps:**

1. Run 4 security scanners
2. Validate Terraform syntax
3. Generate deployment plan
4. Wait for manual approval
5. Deploy infrastructure
6. Generate SBOM for audit

### 4. Access Deployment

Terraform outputs:

```
cloudfront_domain = "d123456abcdef.cloudfront.net"
instance_public_ip = "203.0.113.45"
```

**Access:**

* CloudFront (recommended): https://d123456abcdef.cloudfront.net
* Direct EC2 (testing): http://203.0.113.45:3000

---

## Infrastructure Components

**Networking:**

* VPC with public/private subnets (or existing)
* Internet Gateway
* Security groups (CloudFront prefix list only)

**Compute:**

* EC2 t3.micro Amazon Linux 2023
* Docker: `bkimminich/juice-shop:15.0.0`
* 20GB encrypted EBS

**CDN & Security:**

* CloudFront HTTPS distribution
* AWS WAF: OWASP Top 10, Known Bad Inputs, IP Reputation, Rate limiting

**Monitoring:**

* CloudWatch alarm (CPU ≥70% for 10 min)
* SNS email alerts
* S3 bucket for CloudFront logs (versioned, encrypted)

**Cost:** ~$98/month

---

## Configuration

**Terraform Variables (`terraform/variables.tf`)**

Required:

* `my_ip_cidr` - SSH IP
* `key_name` - EC2 key pair
* `alert_email` - CloudWatch alerts
* `logs_bucket_name` - Unique S3 bucket

Optional:

* `region` - AWS region (default: us-east-2)
* `instance_type` - EC2 type (default: t3.micro)
* `juice_shop_image` - Docker image (default: 15.0.0)

**Examples:**

Change Docker version:

```hcl
variable "juice_shop_image" {
  default = "bkimminich/juice-shop:16.0.0"
}
```

Adjust WAF rate limit:

```hcl
limit = 500  # Down from 1000
```

---

## Destroy Infrastructure

### GitHub Actions (Recommended)

1. Actions → Juice Shop Destroy Infrastructure
2. Run workflow, type `DESTROY`
3. Approve

### Manual

```bash
cd terraform
export TF_VAR_alert_email="your-email@example.com"
export TF_VAR_key_name="your-keypair"
export TF_VAR_logs_bucket_name="your-unique-bucket"
export TF_VAR_my_ip_cidr="YOUR.IP/32"

terraform destroy
```

**Warning:** Deletes all infrastructure and logs.

---

## Testing & Validation

**Security Scans (Local):**

```bash
checkov -d terraform/ --framework terraform
cd terraform && tflint --init && tflint
trivy config terraform/
tfsec terraform/
```

**Integration Tests:**

```bash
curl -I https://YOUR_CLOUDFRONT_DOMAIN  # Expect HTTP/2 200
for i in {1..1100}; do curl -s https://YOUR_CLOUDFRONT_DOMAIN > /dev/null; done  # 403 after ~1000
```

---

## Monitoring

**CloudWatch Alarms:** CPU ≥70% for 10 min → Email via SNS

**Logs:** CloudFront access logs (S3), Docker logs (`docker logs juice`)

---

## Troubleshooting

**Terraform state locked:**

```bash
aws dynamodb scan --table-name LOCK_TABLE_NAME
terraform force-unlock LOCK_ID
```

**SSH connection refused:**

```bash
aws ec2 describe-security-groups --group-ids sg-XXXXX
aws ec2 describe-instances --instance-ids i-XXXXX
```

**WAF not blocking attacks:** Check association, CloudWatch logs, test with payloads

**Need Help:**

* [Open an issue](https://github.com/AFP9272000/secure-vulnerable-website-juiceshop/issues)
* Contact: Your Email

---

## What You'll Learn

**Cloud Engineering:** VPC, CloudFront, WAF, EC2, S3, CloudWatch, cost optimization

**Security:** OIDC, defense-in-depth, WAF, security groups

**DevOps:** Terraform + S3/DynamoDB state, CI/CD pipelines, drift detection

**Professional Skills:** Documentation, architecture, compliance, incident response

---

## Related Certifications

* AWS Certified Solutions Architect (Professional)
* AWS Certified Security (Specialty)
* AWS Certified DevOps Engineer (Professional)
* HashiCorp Certified: Terraform Associate

---

## License

MIT License - see [LICENSE](LICENSE)

---

## About

**Built by:** Addison Pirlo

**GitHub:** [@AFP9272000](https://github.com/AFP9272000)

**LinkedIn:** [Connect](https://linkedin.com/in/your-profile)

**Tech Stack:** AWS • Terraform • GitHub Actions • Docker • Python

---

## Show Your Support

If this project helped you learn DevSecOps practices, please give it a star. It helps others discover the project and motivates continued development.

---

**Note:** Deploys intentionally vulnerable OWASP Juice Shop for educational purposes. Security layers demonstrated are production-ready patterns applicable to any web application.

Built with a focus on **security-first engineering** and **DevOps best practices**.
