#######################
# Default Network ACLs
#######################
resource "aws_default_network_acl" "this" {
  count = "${var.create_vpc && var.manage_default_network_acl ? 1 : 0}"

  default_network_acl_id = "${element(concat(aws_vpc.this.*.default_network_acl_id, list("")), 0)}"

  ingress = "${var.default_network_acl_ingress}"
  egress  = "${var.default_network_acl_egress}"

  tags = "${merge(map("Name", format("%s", var.default_network_acl_name)), var.tags, var.default_network_acl_tags)}"

  lifecycle {
    ignore_changes = ["subnet_ids"]
  }
}

########################
# Public Network ACLs
########################
resource "aws_network_acl" "public" {
  count = "${var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id     = "${element(concat(aws_vpc.this.*.id, list("")), 0)}"
  subnet_ids = ["${aws_subnet.public.*.id}"]

  tags = "${merge(map("Name", format("%s-${var.public_subnet_suffix}", var.name)), var.tags, var.public_acl_tags)}"
}

resource "aws_network_acl_rule" "public_inbound" {
  count = "${var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_inbound_acl_rules) : 0}"

  network_acl_id = "${aws_network_acl.public.id}"

  egress      = false
  rule_number = "${lookup(var.public_inbound_acl_rules[count.index], "rule_number")}"
  rule_action = "${lookup(var.public_inbound_acl_rules[count.index], "rule_action")}"
  from_port   = "${lookup(var.public_inbound_acl_rules[count.index], "from_port")}"
  to_port     = "${lookup(var.public_inbound_acl_rules[count.index], "to_port")}"
  protocol    = "${lookup(var.public_inbound_acl_rules[count.index], "protocol")}"
  cidr_block  = "${lookup(var.public_inbound_acl_rules[count.index], "cidr_block")}"
}

resource "aws_network_acl_rule" "public_outbound" {
  count = "${var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_outbound_acl_rules) : 0}"

  network_acl_id = "${aws_network_acl.public.id}"

  egress      = true
  rule_number = "${lookup(var.public_outbound_acl_rules[count.index], "rule_number")}"
  rule_action = "${lookup(var.public_outbound_acl_rules[count.index], "rule_action")}"
  from_port   = "${lookup(var.public_outbound_acl_rules[count.index], "from_port")}"
  to_port     = "${lookup(var.public_outbound_acl_rules[count.index], "to_port")}"
  protocol    = "${lookup(var.public_outbound_acl_rules[count.index], "protocol")}"
  cidr_block  = "${lookup(var.public_outbound_acl_rules[count.index], "cidr_block")}"
}

#######################
# Private Network ACLs
#######################
resource "aws_network_acl" "private" {
  count = "${var.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? 1 : 0}"

  vpc_id     = "${element(concat(aws_vpc.this.*.id, list("")), 0)}"
  subnet_ids = ["${aws_subnet.private.*.id}"]

  tags = "${merge(map("Name", format("%s-${var.private_subnet_suffix}", var.name)), var.tags, var.private_acl_tags)}"
}

resource "aws_network_acl_rule" "private_inbound" {
  count = "${var.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? length(var.private_inbound_acl_rules) : 0}"

  network_acl_id = "${aws_network_acl.private.id}"

  egress      = false
  rule_number = "${lookup(var.private_inbound_acl_rules[count.index], "rule_number")}"
  rule_action = "${lookup(var.private_inbound_acl_rules[count.index], "rule_action")}"
  from_port   = "${lookup(var.private_inbound_acl_rules[count.index], "from_port")}"
  to_port     = "${lookup(var.private_inbound_acl_rules[count.index], "to_port")}"
  protocol    = "${lookup(var.private_inbound_acl_rules[count.index], "protocol")}"
  cidr_block  = "${lookup(var.private_inbound_acl_rules[count.index], "cidr_block")}"
}

resource "aws_network_acl_rule" "private_outbound" {
  count = "${var.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? length(var.private_outbound_acl_rules) : 0}"

  network_acl_id = "${aws_network_acl.private.id}"

  egress      = true
  rule_number = "${lookup(var.private_outbound_acl_rules[count.index], "rule_number")}"
  rule_action = "${lookup(var.private_outbound_acl_rules[count.index], "rule_action")}"
  from_port   = "${lookup(var.private_outbound_acl_rules[count.index], "from_port")}"
  to_port     = "${lookup(var.private_outbound_acl_rules[count.index], "to_port")}"
  protocol    = "${lookup(var.private_outbound_acl_rules[count.index], "protocol")}"
  cidr_block  = "${lookup(var.private_outbound_acl_rules[count.index], "cidr_block")}"
}

#######################
# NAT Network ACLs
#######################
resource "aws_network_acl" "nat" {
  count = "${var.create_vpc && var.nat_dedicated_network_acl && length(var.nat_subnets) > 0 ? 1 : 0}"

  vpc_id     = "${element(concat(aws_vpc.this.*.id, list("")), 0)}"
  subnet_ids = ["${aws_subnet.nat.*.id}"]

  tags = "${merge(map("Name", format("%s-${var.nat_subnet_suffix}", var.name)), var.tags, var.nat_acl_tags)}"
}

resource "aws_network_acl_rule" "nat_inbound" {
  count = "${var.create_vpc && var.nat_dedicated_network_acl && length(var.nat_subnets) > 0 ? length(var.nat_inbound_acl_rules) : 0}"

  network_acl_id = "${aws_network_acl.nat.id}"

  egress      = false
  rule_number = "${lookup(var.nat_inbound_acl_rules[count.index], "rule_number")}"
  rule_action = "${lookup(var.nat_inbound_acl_rules[count.index], "rule_action")}"
  from_port   = "${lookup(var.nat_inbound_acl_rules[count.index], "from_port")}"
  to_port     = "${lookup(var.nat_inbound_acl_rules[count.index], "to_port")}"
  protocol    = "${lookup(var.nat_inbound_acl_rules[count.index], "protocol")}"
  cidr_block  = "${lookup(var.nat_inbound_acl_rules[count.index], "cidr_block")}"
}

resource "aws_network_acl_rule" "nat_outbound" {
  count = "${var.create_vpc && var.nat_dedicated_network_acl && length(var.nat_subnets) > 0 ? length(var.nat_outbound_acl_rules) : 0}"

  network_acl_id = "${aws_network_acl.nat.id}"

  egress      = true
  rule_number = "${lookup(var.nat_outbound_acl_rules[count.index], "rule_number")}"
  rule_action = "${lookup(var.nat_outbound_acl_rules[count.index], "rule_action")}"
  from_port   = "${lookup(var.nat_outbound_acl_rules[count.index], "from_port")}"
  to_port     = "${lookup(var.nat_outbound_acl_rules[count.index], "to_port")}"
  protocol    = "${lookup(var.nat_outbound_acl_rules[count.index], "protocol")}"
  cidr_block  = "${lookup(var.nat_outbound_acl_rules[count.index], "cidr_block")}"
}
