###########
### VPC ###
###########
resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr}"
  instance_tenancy     = "${var.instance_tenancy}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"
  enable_dns_support   = "${var.enable_dns_support}"

  tags = "${merge(var.tags, map("Name", format("%s", var.name)))}"
}

###############
### Gateway ###
###############

### Internet Gateway ###
resource "aws_internet_gateway" "main" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge(var.tags, map("Name", format("%s-igw", var.name)))}"
}

### NAT Gateway ###
resource "aws_eip" "nat" {
  count = "${var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.nat_azs)) : 0}"

  vpc = true
}

resource "aws_nat_gateway" "main" {
  count = "${var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.nat_azs)) : 0}"

  allocation_id = "${element(aws_eip.nat.*.id, (var.single_nat_gateway ? 0 : count.index))}"
  subnet_id     = "${element(aws_subnet.public.*.id, (var.single_nat_gateway ? 0 : count.index))}"

  depends_on = ["aws_internet_gateway.main"]
}

resource "aws_route" "nat_subnet_gateway" {
  count = "${var.enable_nat_gateway ? length(var.nat_azs) : 0}"

  route_table_id         = "${element(aws_route_table.nat.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.main.*.id, count.index)}"
}

##############
### Subnet ###
##############

### Public subnet ###
resource "aws_subnet" "public" {
  count = "${length(var.public_subnets)}"

  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.public_subnets[count.index]}"
  availability_zone       = "${element(var.public_azs, count.index)}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  tags = "${merge(var.tags, map("Name", format("%s-public-%s", var.name, element(var.public_footer, count.index))))}"
}

### Private subnet ###
resource "aws_subnet" "private" {
  count = "${length(var.private_subnets)}"

  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.private_subnets[count.index]}"
  availability_zone = "${element(var.private_azs, count.index)}"

  tags = "${merge(var.tags, map("Name", format("%s-private-%s", var.name, element(var.private_footer, count.index))))}"
}

### NAT subnet ###
resource "aws_subnet" "nat" {
  count = "${length(var.nat_subnets)}"

  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${var.nat_subnets[count.index]}"
  availability_zone = "${element(var.nat_azs, count.index)}"

  tags = "${merge(var.tags, map("Name", format("%s-nat-%s", var.name, element(var.private_footer, count.index))))}"
}

###################
### Route Table ### 
###################

### Public routes ###
resource "aws_route_table" "public" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id           = "${aws_vpc.main.id}"
  propagating_vgws = ["${var.public_propagating_vgws}"]

  tags = "${merge(var.tags, map("Name", format("%s-public", var.name)))}"
}

resource "aws_route" "public_internet_gateway" {
  count = "${length(var.public_subnets) > 0 ? 1 : 0}"

  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

### Private routes ###
resource "aws_route_table" "private" {
  count = "${length(var.private_azs)}"

  vpc_id           = "${aws_vpc.main.id}"
  propagating_vgws = ["${var.private_propagating_vgws}"]

  tags = "${merge(var.tags, map("Name", format("%s-private-%s", var.name, element(var.private_footer, count.index))))}"
}

resource "aws_route" "private_routes" {
  count = "${length(var.private_route_cidr) > 0 ? 1 : 0}"

  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "${var.private_route_cidr}"
  network_interface_id   = "${var.private_route_eni}"
  instance_id            = "${var.private_route_instance}"
  gateway_id             = "${var.private_route_gw}"
}

### NAT routes ###
resource "aws_route_table" "nat" {
  count = "${length(var.nat_azs)}"

  vpc_id           = "${aws_vpc.main.id}"
  propagating_vgws = ["${var.nat_propagating_vgws}"]

  tags = "${merge(var.tags, map("Name", format("%s-nat-%s", var.name, element(var.nat_footer, count.index))))}"
}

resource "aws_route" "nat_routes" {
  count = "${length(var.nat_route_cidr) > 0 ? 1 : 0}"

  route_table_id         = "${element(aws_route_table.nat.*.id, count.index)}"
  destination_cidr_block = "${var.nat_route_cidr}"
  network_interface_id   = "${var.nat_route_eni}"
  instance_id            = "${var.nat_route_instance}"
  gateway_id             = "${var.nat_route_gw}"
}

###############################
### Route table association ###
###############################
resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnets)}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnets)}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route_table_association" "nat" {
  count = "${length(var.nat_subnets)}"

  subnet_id      = "${element(aws_subnet.nat.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.nat.*.id, count.index)}"
}

####################
### DHCP Options ###
####################
resource "aws_vpc_dhcp_options" "main" {
  count = "${var.dhcp_options}"

  domain_name          = "${var.domain_name}"
  domain_name_servers  = ["${compact(var.domain_name_servers)}"]
  ntp_servers          = ["${compact(var.ntp_servers)}"]
  netbios_name_servers = ["${compact(var.netbios_name_servers)}"]
  netbios_node_type    = "${var.netbios_node_type}"

  tags = "${merge(var.tags, map("Name", format("%s-set-dhcp", var.name)))}"
}

resource "aws_vpc_dhcp_options_association" "main" {
  count = "${var.dhcp_options}"

  dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
  vpc_id          = "${aws_vpc.main.id}"
}
