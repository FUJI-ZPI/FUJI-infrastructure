terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.93.0"
    }
  }
}

provider "aws" {
    region = "eu-central-1"
}

resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "main_vpc"
    }
}

# _____________________________ public subnet _________________________

resource "aws_subnet" "public_subnet_a" {
    vpc_id            = aws_vpc.main_vpc.id
    cidr_block        = "10.0.1.0/24"
    availability_zone = "${data.aws_region.current.name}a"
    map_public_ip_on_launch = true
    tags = {
        Name = "public_subnet_a"
    }
}

resource "aws_subnet" "public_subnet_b" {
    vpc_id            = aws_vpc.main_vpc.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "${data.aws_region.current.name}b"
    map_public_ip_on_launch = true
    tags = {
        Name = "public_subnet_b"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "main_igw"
    }
}

resource "aws_route_table" "public_rt_a" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "public_rt_a"
    }
}

resource "aws_route_table" "public_rt_b" {
    vpc_id = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "public_rt_b"
    }
}

resource "aws_route_table_association" "public_assoc_a" {
    subnet_id      = aws_subnet.public_subnet_a.id
    route_table_id = aws_route_table.public_rt_a.id
}

resource "aws_route_table_association" "public_assoc_b" {
    subnet_id      = aws_subnet.public_subnet_b.id
    route_table_id = aws_route_table.public_rt_b.id
}

# _____________________________________________________________________________

# _____________________________ private subnet ________________________________

resource "aws_subnet" "private_subnet_a" {
    vpc_id            = aws_vpc.main_vpc.id
    cidr_block        = "10.0.3.0/24"
    availability_zone = "${data.aws_region.current.name}a"
    tags = {
        Name = "private_subnet_a"
    }
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id            = aws_vpc.main_vpc.id
    cidr_block        = "10.0.4.0/24"
    availability_zone = "${data.aws_region.current.name}b"
    tags = {
        Name = "private_subnet_b"
    }
}

resource "aws_subnet" "private_subnet_db_a" {
    vpc_id            = aws_vpc.main_vpc.id
    cidr_block        = "10.0.5.0/24"
    availability_zone = "${data.aws_region.current.name}a"
    tags = {
        Name = "private_subnet_db_a"
    }
}

resource "aws_subnet" "private_subnet_db_b" {
    vpc_id            = aws_vpc.main_vpc.id
    cidr_block        = "10.0.6.0/24"
    availability_zone = "${data.aws_region.current.name}b"
    tags = {
        Name = "private_subnet_db_b"
    }
}

resource "aws_route_table" "private_rt_a" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "private_rt_a"
    }
}

resource "aws_route_table" "private_rt_b" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "private_rt_b"
    }
}

resource "aws_route_table" "private_rt_db_a" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "private_rt_db_a"
    }
}

resource "aws_route_table" "private_rt_db_b" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "private_rt_db_b"
    }
}

resource "aws_route_table_association" "private_assoc_a" {
    subnet_id      = aws_subnet.private_subnet_a.id
    route_table_id = aws_route_table.private_rt_a.id
}

resource "aws_route_table_association" "private_assoc_b" {
    subnet_id      = aws_subnet.private_subnet_b.id
    route_table_id = aws_route_table.private_rt_b.id
}

resource "aws_route_table_association" "private_assoc_db_a" {
    subnet_id      = aws_subnet.private_subnet_db_a.id
    route_table_id = aws_route_table.private_rt_db_a.id
}

resource "aws_route_table_association" "private_assoc_db_b" {
    subnet_id      = aws_subnet.private_subnet_db_b.id
    route_table_id = aws_route_table.private_rt_db_b.id
}
# _____________________________________________________________________________

# _____________________________ NAT Gateway ___________________________________

resource "aws_eip" "nat_eip_a" {
    domain = "vpc"
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "nat_eip_a"
    }
}

resource "aws_eip" "nat_eip_b" {
    domain = "vpc"
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "nat_eip_b"
    }
}

resource "aws_nat_gateway" "nat_gw_a" {
    allocation_id = aws_eip.nat_eip_a.id
    subnet_id     = aws_subnet.public_subnet_a.id
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "nat_gw_a"
  }
}

resource "aws_nat_gateway" "nat_gw_b" {
    allocation_id = aws_eip.nat_eip_b.id
    subnet_id     = aws_subnet.public_subnet_b.id
    depends_on = [aws_internet_gateway.igw]
    tags = {
        Name = "nat_gw_b"
  }
}

resource "aws_route" "private_nat_route_a" {
    route_table_id         = aws_route_table.private_rt_a.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gw_a.id
}

resource "aws_route" "private_nat_route_b" {
    route_table_id         = aws_route_table.private_rt_b.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gw_b.id
}

resource "aws_route" "private_nat_route_db_a" {
    route_table_id         = aws_route_table.private_rt_db_a.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gw_a.id
}

resource "aws_route" "private_nat_route_db_b" {
    route_table_id         = aws_route_table.private_rt_db_b.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gw_b.id
}

# AWS Systems Manager VPC Endpoint
resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ssm_endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  security_group_ids = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ssmmessages_endpoint"
  }
}

resource "aws_security_group" "ssm_endpoint_sg" {
        name   = "ssm_endpoint_sg"
        vpc_id = aws_vpc.main_vpc.id

    ingress {
        description = "Allow HTTPS traffic from within the VPC"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [aws_vpc.main_vpc.cidr_block]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "ssm_endpoint_sg"
    }
}
