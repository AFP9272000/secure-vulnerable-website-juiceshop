# If passing a vpc_id/subnet_id, these resources won't be created (count = 0)

# Create a minimal public VPC (avoids having to create a vpc via script or console)
resource "aws_vpc" "lab" {
  count                = var.vpc_id == "" ? 1 : 0
  cidr_block           = "10.42.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.tags, { Name = "${var.project}-vpc" })
}

resource "aws_internet_gateway" "lab" {
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = aws_vpc.lab[0].id
  tags   = merge(local.tags, { Name = "${var.project}-igw" })
}

resource "aws_subnet" "lab_public" {
  count                   = var.subnet_id == "" ? 1 : 0
  vpc_id                  = var.vpc_id == "" ? aws_vpc.lab[0].id : var.vpc_id
  cidr_block              = "10.42.1.0/24"
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${var.project}-public-a" })
}

resource "aws_route_table" "lab_public" {
  count  = var.vpc_id == "" ? 1 : 0
  vpc_id = aws_vpc.lab[0].id
  tags   = merge(local.tags, { Name = "${var.project}-rt-public" })
}

resource "aws_route" "lab_igw" {
  count                  = var.vpc_id == "" ? 1 : 0
  route_table_id         = aws_route_table.lab_public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab[0].id
}

resource "aws_route_table_association" "lab_public" {
  count          = var.subnet_id == "" ? 1 : 0
  subnet_id      = aws_subnet.lab_public[0].id
  route_table_id = var.vpc_id == "" ? aws_route_table.lab_public[0].id : ""
}

# Resolve the IDs I will actually use everywhere else
locals {
  use_vpc_id    = var.vpc_id != "" ? var.vpc_id : (length(aws_vpc.lab) > 0 ? aws_vpc.lab[0].id : var.vpc_id)
  use_subnet_id = var.subnet_id != "" ? var.subnet_id : (length(aws_subnet.lab_public) > 0 ? aws_subnet.lab_public[0].id : var.subnet_id)
}
