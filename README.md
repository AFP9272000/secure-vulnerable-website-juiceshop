# Secure Vulnerable Web Application with DevSecOps Pipeline

[![Terraform](https://img.shields.io/badge/Terraform-1.6.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)

> Production-grade DevSecOps implementation deploying OWASP Juice Shop on AWS with automated security scanning, zero-credential authentication, and infrastructure as code.

---

## Overview

This project demonstrates a **complete DevSecOps pipeline** for deploying a vulnerable web application securely:

* **Zero-credential security** via OIDC (no AWS keys stored)
* **Automated security scanning**: Checkov, TFLint, Trivy, tfsec
* **Multi-layer defense**: CloudFront → WAF → Security Groups → Docker
* **Infrastructure drift detection**
* **CI/CD with approval gates** for production
* **Remote state management** with S3 + DynamoDB locking

**Purpose:** Deploy a vulnerable application securely while implementing enterprise-grade DevOps practices.

---

## Architecture

```
Internet → CloudFront → AWS WAF → Security Group → EC2 (Docker: Juice Shop) → Monitoring & Logs
```

**Security Layers:**

1. **Edge:** CloudFront with custom security headers
2. **Application Firewall:** AWS WAF with managed rules + rate limiting
3. **Network:** Security group restricting access to CloudFront
4. **Container:** Docker isolation with version-pinned image

---

## DevSecOps Pipeline

**Security Scanning:** Triggered on every commit

| Scanner | Purpose                  |
| ------- | ------------------------ |
| Checkov | Policy violations        |
| TFLint  | Terraform best practices |
| Trivy   | CVE detection            |
| tfsec   | AWS misconfigurations    |

**CI/CD Workflow:**

```
Git Push → Security Scans → Terraform Validate → Plan → Manual Approval → Apply
```

**Zero-Credential OIDC:** Temporary GitHub-issued tokens; no stored secrets required.

---

## Key Technologies

* **Cloud:** AWS VPC, EC2, CloudFront, WAF, S3, CloudWatch
* **Infrastructure as Code:** Terraform
* **CI/CD:** GitHub Actions
* **Containerization:** Docker
* **Security:** OIDC authentication, multi-layer defense, automated scanning

---

## Learning Outcomes

* **Cloud Engineering:** Multi-layer architecture, CDN, firewall, monitoring
* **Security:** OIDC, defense-in-depth, security group patterns, WAF
* **DevOps:** CI/CD pipelines, drift detection, Terraform state management
* **Professional Skills:** Documentation, architecture design, compliance awareness

---

## About

**Built by:** Addison Pirlo
**GitHub:** [@AFP9272000](https://github.com/AFP9272000)
**LinkedIn:** (www.linkedin.com/in/addison-p-6406b225b)
**Tech Stack:** AWS • Terraform • GitHub Actions • Docker • Python

---

**Note:** OWASP Juice Shop is intentionally vulnerable for educational purposes. Security layers demonstrated are production-ready patterns for securing web applications.

Built with a focus on **security-first engineering** and **DevOps best practices**.
