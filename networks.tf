###########################################
#                 VPCs
###########################################
# Create VPC in us-east-1
resource "aws_vpc" "vpc_master" {
  provider             = aws.region_master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master_vpc_jenkins"
  }
}

# Create VPC in us-wes-2
resource "aws_vpc" "vpc_master_oregon" {
  provider             = aws.region_worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker_vpc_jenkins"
  }
}

##########################################
#                IGW
##########################################
# Create IGW in us-east-1
resource "aws_internet_gateway" "igw" {
  provider = aws.region_master
  vpc_id   = aws_vpc.vpc_master.id
}

# Create IGW in us-west-2
resource "aws_internet_gateway" "igw_oregon" {
  provider = aws.region_worker
  vpc_id   = aws_vpc.vpc_master_oregon.id
}


##########################################
#               SUBNETS
##########################################
# Get all available AZ's in VPC for master region
data "aws_availability_zones" "azs" {
  provider = aws.region_master
  state    = "available"
}

# Create subnet #1 in us-east-1
resource "aws_subnet" "subnet_1" {
  provider          = aws.region_master
  availability_zone = element(data.aws_availability_zones.azs.zone_ids, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
}

# Create subnet #2 in us-east-1
resource "aws_subnet" "subnet_2" {
  provider          = aws.region_master
  availability_zone = element(data.aws_availability_zones.azs.zone_ids, 1)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
}

# Create subnet #º in us-west-2
resource "aws_subnet" "subnet_1_oregon" {
  provider   = aws.region_worker
  vpc_id     = aws_vpc.vpc_master_oregon.id
  cidr_block = "192.168.1.0/24"
}

########################################
#              VPC PEERING
########################################
# Initiate Peering connection request from us-east-1
resource "aws_vpc_peering_connection" "useast1_uswest2" {
  provider    = aws.region_master
  peer_vpc_id = aws_vpc.vpc_master_oregon.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region_worker
}

resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region_worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  auto_accept               = true
}

########################################
#            ROUTING TABLE
########################################
# Create routing table in us-east-1
resource "aws_route_table" "internet_route" {
  provider = aws.region_master
  vpc_id   = aws_vpc.vpc_master.id

  # Route towards Internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # Route towards us-west-2
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "Master-Region-RT"
  }
}

# Overwrite default route table of VPC(Master) with our route table entries
resource "aws_main_route_table_association" "set_master_default_rt_assoc" {
  provider       = aws.region_master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

# Create routing table in us-west-2
resource "aws_route_table" "internet_route_oregon" {
  provider = aws.region_worker
  vpc_id   = aws_vpc.vpc_master_oregon.id

  # Route towards Internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_oregon.id
  }

  # Route towards us-east-1
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "Worker-Region_RT"
  }
}

# Overwrite default route table of VPC(Worker) with our route table entries
resource "aws_main_route_table_association" "set_worker_default_rt_assoc" {
  provider       = aws.region_worker
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route_oregon.id
}