provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {}
}

resource "aws_vpc" "test-vpc" {
  cidr_block            = "${var.vpc_cidr}"
  enable_dns_hostnames  = true

  tags {
    Name = "Test-VPC"
  }
}

resource "aws_subnet" "public-subnet-1" {
  cidr_block        = "${var.public_subnet_1_cidr}"
  vpc_id            = "${aws_vpc.test-vpc.id}"
  availability_zone = "${var.region}a"

  tags {
    Name = "Public-Subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  cidr_block        = "${var.public_subnet_2_cidr}"
  vpc_id            = "${aws_vpc.test-vpc.id}"
  availability_zone = "${var.region}b"

  tags {
    Name = "Public-Subnet-2"
  }
}

resource "aws_subnet" "private-subnet-1" {
  cidr_block        = "${var.private_subnet_1_cidr}"
  vpc_id            = "${aws_vpc.test-vpc.id}"
  availability_zone = "${var.region}a"

  tags {
    Name = "Private-Subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  cidr_block        = "${var.private_subnet_2_cidr}"
  vpc_id            = "${aws_vpc.test-vpc.id}"
  availability_zone = "${var.region}b"

  tags {
    Name = "Private-Subnet-2"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.test-vpc.id}"

  tags {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = "${aws_vpc.test-vpc.id}"

  tags {
    Name = "Private-Route-Table"
  }
}

resource "aws_route_table_association" "public-subnet-1-association" {
  route_table_id  = "${aws_route_table.public-route-table.id}"
  subnet_id       = "${aws_subnet.public-subnet-1.id}"
}

resource "aws_route_table_association" "public-subnet-2-association" {
  route_table_id  = "${aws_route_table.public-route-table.id}"
  subnet_id       = "${aws_subnet.public-subnet-2.id}"
}

resource "aws_route_table_association" "private-subnet-1-association" {
  route_table_id  = "${aws_route_table.private-route-table.id}"
  subnet_id       = "${aws_subnet.private-subnet-1.id}"
}

resource "aws_route_table_association" "private-subnet-2-association" {
  route_table_id  = "${aws_route_table.private-route-table.id}"
  subnet_id       = "${aws_subnet.private-subnet-2.id}"
}

resource "aws_eip" "elastic-ip-for-nat-gw" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"

  tags {
    Name = "Test-EIP"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.elastic-ip-for-nat-gw.id}"
  subnet_id     = "${aws_subnet.public-subnet-1.id}"

  tags {
    Name = "Test-NAT-GW"
  }

  depends_on = ["aws_eip.elastic-ip-for-nat-gw"]
}

resource "aws_route" "nat-gw-route" {
  route_table_id          = "${aws_route_table.private-route-table.id}"
  nat_gateway_id          = "${aws_nat_gateway.nat-gw.id}"
  destination_cidr_block  = "0.0.0.0/0"
}

resource "aws_internet_gateway" "test-igw" {
  vpc_id = "${aws_vpc.test-vpc.id}"

  tags {
    Name = "Test-IGW"
  }
}

resource "aws_route" "public-internet-gw-route" {
  route_table_id          = "${aws_route_table.public-route-table.id}"
  gateway_id              = "${aws_internet_gateway.test-igw.id}"
  destination_cidr_block  = "0.0.0.0/0"
}
