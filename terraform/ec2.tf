# Security group that:
# - Allows SSH from my IP only
# - Allows HTTP app port (3000) ONLY from CloudFront origin-facing IP prefix list
resource "aws_security_group" "juice" {
  name        = "${var.project}-sg"
  description = "Lock EC2 to CloudFront origin-facing IPs and allow SSH from my IP"
  vpc_id      = local.use_vpc_id
  tags        = local.tags
}

# Allow SSH from MY IP (change via variable)
resource "aws_security_group_rule" "ssh_in" {
  type              = "ingress"
  security_group_id = aws_security_group.juice.id
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [var.my_ip_cidr]
  description       = "SSH from my IP only"
}

# References AWS-managed prefix list that represents CloudFront servers WHEN THEY CALL ORIGINS
data "aws_ec2_managed_prefix_list" "cf_origin" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Only CloudFront may reach port 3000
resource "aws_security_group_rule" "app_in_from_cf" {
  type              = "ingress"
  security_group_id = aws_security_group.juice.id
  protocol          = "tcp"
  from_port         = 3000
  to_port           = 3000
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cf_origin.id]
  description       = "App traffic from CloudFront origin-facing IPs only"
}

# Egress: allow all (So the instance can pull the Docker image)
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.juice.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Outbound"
}

# User data: install Docker and run Juice Shop on 3000
# NOTE: Docker image is public; no IAM role is required
locals {
  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    LOG=/var/log/user-data.log
    exec > >(tee -a "$LOG") 2>&1

    echo "[user-data] start $(date -Is)"

    #--- wait for network (up to ~2 min) ---
    for i in {1..24}; do
      if curl -sSf https://aws.amazon.com >/dev/null; then
        echo "[user-data] network OK"
        break
      fi
      echo "[user-data] waiting for network... ($i)"
      sleep 5
    done

    #--- install docker (Amazon Linux 2023) ---
    dnf -y update || true
    dnf -y install docker cloud-utils-growpart xfsprogs
    systemctl enable --now docker

    # allow ec2-user to use docker (future SSH convenience)
    usermod -aG docker ec2-user || true

    #--- prune any leftovers (just in case) ---
    docker system prune -af || true

    #--- pull image (retry up to 5 times) ---
    for i in {1..5}; do
      if docker pull bkimminich/juice-shop:latest; then
        echo "[user-data] image pulled"
        break
      fi
      echo "[user-data] pull failed, retry ($i)"
      sleep 5
    done

    # stop/remove any old container with same name
    docker rm -f juice || true

    #--- run container on 3000 ---
    docker run -d --name juice --restart unless-stopped -p 3000:3000 bkimminich/juice-shop:latest

    #--- readiness check (wait up to ~60s) ---
    for i in {1..30}; do
      if curl -sSf http://localhost:3000 >/dev/null; then
        echo "[user-data] app is up"
        break
      fi
      echo "[user-data] waiting for app... ($i)"
      sleep 2
    done

    echo "[user-data] done $(date -Is)"
  EOT
}

resource "aws_instance" "juice" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = local.use_subnet_id
  vpc_security_group_ids      = [aws_security_group.juice.id]
  key_name                    = var.key_name
  user_data                   = local.user_data
  associate_public_ip_address = true # public origin behind CloudFront

  # expand root disk to 20 GiB (default is ~8 GiB)
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = merge(local.tags, { Name = "${var.project}-ec2" })
}

# Look up a recent Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  owners      = ["137112412989"] # Amazon
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
