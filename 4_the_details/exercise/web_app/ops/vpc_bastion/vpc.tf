# The top level VPC Resource
# CIDR blocks can be selected based on the Teraform workspace you're using.
resource "aws_vpc" "elixir-in-the-jungle" {
  cidr_block = "${lookup(var.vpc_cidr_blocks, terraform.workspace)}"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}


# This is the private subnet for internal communication
resource "aws_subnet" "private" {
  availability_zone = "${var.region}a"
  cidr_block = "${cidrsubnet(aws_vpc.elixir-in-the-jungle.cidr_block, 8, 11)}"
  map_public_ip_on_launch = false
  vpc_id = "${aws_vpc.elixir-in-the-jungle.id}"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}

# This is a secondary private subnet, RDS requires at least two
# subnets in differing availability zones for more information:
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.WorkingWithRDSInstanceinaVPC.html
resource "aws_subnet" "private-b" {
  availability_zone = "${var.region}b"
  cidr_block = "${cidrsubnet(aws_vpc.elixir-in-the-jungle.cidr_block, 8, 10)}"
  map_public_ip_on_launch = false
  vpc_id = "${aws_vpc.elixir-in-the-jungle.id}"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}

# This defines the public subnet, and is used to contain the load balancer,
# and the Bastion server, both of which need to be accessed from outside
# the VPC.
resource "aws_subnet" "public" {
  availability_zone = "${var.region}a"
  cidr_block = "${cidrsubnet(aws_vpc.elixir-in-the-jungle.cidr_block, 8, 12)}"
  map_public_ip_on_launch = true
  vpc_id = "${aws_vpc.elixir-in-the-jungle.id}"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}


# Everything below this point is used to setup VPC routing tables and
# associations, more information about the individual pieces can be found:
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
resource "aws_internet_gateway" "elixir-in-the-jungle" {
  vpc_id = "${aws_vpc.elixir-in-the-jungle.id}"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}


# This creates an IP we can associate with the NAT gateway later
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}


# Associate the IP with the public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public.id}"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}


resource "aws_default_route_table" "elixir-in-the-jungle" {
  default_route_table_id = "${aws_vpc.elixir-in-the-jungle.default_route_table_id}"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}


resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.elixir-in-the-jungle.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.elixir-in-the-jungle.id}"
  }

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = "${aws_route_table.public.id}"
  subnet_id = "${aws_subnet.public.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.elixir-in-the-jungle.id}"

  tags = {
    Name = "elixir-in-the-jungle"
    Environment = "${terraform.workspace}"
  }

}

resource "aws_route" "nat" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = "${aws_route_table.private.id}"
  nat_gateway_id = "${aws_nat_gateway.nat.id}"
}

resource "aws_route_table_association" "private" {
  route_table_id = "${aws_route_table.private.id}"
  subnet_id = "${aws_subnet.private.id}"
}
