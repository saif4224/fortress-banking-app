# The VPC 
resource "aws_vpc" "fortress_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "Fortress-VPC" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.fortress_vpc.id
  tags = { Name = "Fortress-IGW" }
}

# Public Subnets 
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.fortress_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "Fortress-Public-1a" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.fortress_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "Fortress-Public-1b" }
}

# Private App Subnets 
resource "aws_subnet" "private_app_1" {
  vpc_id            = aws_vpc.fortress_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "Fortress-App-Private-1a" }
}

resource "aws_subnet" "private_app_2" {
  vpc_id            = aws_vpc.fortress_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "Fortress-App-Private-1b" }
}

# Private Data Subnets 
resource "aws_subnet" "private_data_1" {
  vpc_id            = aws_vpc.fortress_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "Fortress-Data-Private-1a" }
}

resource "aws_subnet" "private_data_2" {
  vpc_id            = aws_vpc.fortress_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "Fortress-Data-Private-1b" }
}

# NAT Gateway 
# We need an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id # Lives in Public Subnet
  tags = { Name = "Fortress-NAT" }
}

# Route Tables 

# Public Route Table (Points to Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.fortress_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Fortress-Public-RT" }
}

# Private Route Table 
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.fortress_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "Fortress-Private-RT" }
}

# Route Table Associations 
resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "app_1" {
  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "app_2" {
  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private_rt.id
}
