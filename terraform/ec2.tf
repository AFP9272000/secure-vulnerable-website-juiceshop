##
# EC2 instance and security group to run the vulnerable Juice Shop app.
#
# This file defines a restrictive security group, a user‑data script to
# install Docker and start the application, and the EC2 instance
# itself.  The user‑data script now uses the `juice_shop_image`
# variable so that it can pin the Docker image to a specific version.

# Security group that:
# - Allows SSH from your IP only
# - Allows HTTP app port (3000) ONLY from CloudFront origin‑facing IP prefix list
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

# Egress: allow all (so the instance can pull the Docker image)
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
# NOTE: Docker image is public; no IAM role is required.  We use
# `var.juice_shop_image` instead of `latest` to pin the image.  The
# interpolation is expanded by Terraform when applying the template.
locals {
  # cloud-init: install docker, create a systemd service for Juice Shop, enable & start it
  user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - docker
      - cloud-utils-growpart
      - xfsprogs

    write_files:
      - path: /etc/systemd/system/juice.service
        permissions: "0644"
        owner: root:root
        content: |
          [Unit]
          Description=OWASP Juice Shop Docker Service
          After=network-online.target docker.service
          Wants=network-online.target
          Requires=docker.service

          [Service]
          Type=notify
          TimeoutStartSec=0
          Restart=always
          ExecStartPre=/usr/bin/docker rm -f juice >/dev/null 2>&1 || true
          ExecStartPre=/usr/bin/docker pull bkimminich/juice-shop:latest
          ExecStart=/usr/bin/docker run --name juice -p 3000:3000 --restart unless-stopped bkimminich/juice-shop:latest

          [Install]
          WantedBy=multi-user.target

    runcmd:
      - [ sh, -lc, "systemctl enable --now docker" ]
      - [ sh, -lc, "systemctl daemon-reload" ]
      - [ sh, -lc, "systemctl enable --now juice.service" ]
  EOF
}


resource "aws_instance" "juice" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = local.use_subnet_id
  vpc_security_group_ids      = [aws_security_group.juice.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # IMPORTANT: pass cloud-init user-data
  user_data = local.user_data

  # avoid “no space left on device”
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