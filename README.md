Secure Vulnerable Web Application with DevSecOps Pipeline






Production-grade DevSecOps implementation deploying OWASP Juice Shop on AWS with automated security scanning, zero-credential authentication, and infrastructure as code.

Overview

This project demonstrates a complete DevSecOps pipeline for deploying a vulnerable web application securely:

Zero-credential security via OIDC (no AWS keys stored)

Automated security scanning: Checkov, TFLint, Trivy, tfsec

Multi-layer defense: CloudFront → WAF → Security Groups → Docker

Infrastructure drift detection

CI/CD with approval gates for production

Remote state management with S3 + DynamoDB locking

Purpose: Deploy a vulnerable application securely while implementing enterprise-grade DevOps practices.

Architecture
Internet → CloudFront → AWS WAF → Security Group → EC2 (Docker: Juice Shop) → Monitoring & Logs


Security Layers:

Edge: CloudFront with custom security headers

Application Firewall: AWS WAF with managed rules + rate limiting

Network: Security group restricting access to CloudFront

Container: Docker isolation with version-pinned image

DevSecOps Pipeline

Security Scanning: Triggered on every commit

Scanner	Purpose
Checkov	Policy violations
TFLint	Terraform best practices
Trivy	CVE detection
tfsec	AWS misconfigurations

CI/CD Workflow:

Git Push → Security Scans → Terraform Validate → Plan → Manual Approval → Apply


Zero-Credential OIDC: Temporary GitHub-issued tokens; no stored secrets required.

Key Technologies

Cloud: AWS VPC, EC2, CloudFront, WAF, S3, CloudWatch

Infrastructure as Code: Terraform

CI/CD: GitHub Actions

Containerization: Docker

Security: OIDC authentication, multi-layer defense, automated scanning

Learning Outcomes

Cloud Engineering: Multi-layer architecture, CDN, firewall, monitoring

Security: OIDC, defense-in-depth, security group patterns, WAF

DevOps: CI/CD pipelines, drift detection, Terraform state management

Professional Skills: Documentation, architecture design, compliance awareness

Certifications Demonstrated

AWS Certified Solutions Architect (Professional)

AWS Certified Security (Specialty)

AWS Certified DevOps Engineer (Professional)

HashiCorp Certified: Terraform Associate

About

Built by: Addison Pirlo
GitHub: @AFP9272000

LinkedIn: Connect

Tech Stack: AWS • Terraform • GitHub Actions • Docker • Python

Note: OWASP Juice Shop is intentionally vulnerable for educational purposes. Security layers demonstrated are production-ready patterns for securing web applications.
