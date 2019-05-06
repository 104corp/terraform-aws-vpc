/**
  * # AWS VPC Terraform module
  * 
  * ![Build Status](https://travis-ci.com/104corp/terraform-aws-vpc.svg?branch=master) ![LicenseBadge](https://img.shields.io/github/license/104corp/terraform-aws-vpc.svg)
  * 
  * Terraform module which creates VPC resources on AWS.
  * 
  * These types of resources are supported:
  * 
  * * [VPC](https://www.terraform.io/docs/providers/aws/r/vpc.html)
  * * [Subnet](https://www.terraform.io/docs/providers/aws/r/subnet.html)
  * * [Route](https://www.terraform.io/docs/providers/aws/r/route.html)
  * * [Route table](https://www.terraform.io/docs/providers/aws/r/route_table.html)
  * * [Internet Gateway](https://www.terraform.io/docs/providers/aws/r/internet_gateway.html)
  * * [NAT Gateway](https://www.terraform.io/docs/providers/aws/r/nat_gateway.html)
  * * [VPN Gateway](https://www.terraform.io/docs/providers/aws/r/vpn_gateway.html)
  * * [VPC Endpoint](https://www.terraform.io/docs/providers/aws/r/vpc_endpoint.html) (S3 and DynamoDB)
  * * [DHCP Options Set](https://www.terraform.io/docs/providers/aws/r/vpc_dhcp_options.html)
  * * [Default VPC](https://www.terraform.io/docs/providers/aws/r/default_vpc.html)
  * 
  * ## Usage
  * 
  * ```hcl
  * module "vpc" {
  *   source = "104corp/vpc/aws"
  * 
  *   name = "my-vpc"
  *   cidr = "10.0.0.0/16"
  * 
  *   azs             = ["ap-northeast-1a", "ap-northeast-1c","ap-northeast-1d"]
  *   private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  *   public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  *   nat_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  * 
  *   enable_vpn_gateway = true
  * 
  *   tags = {
  *     Terraform = "true"
  *     Environment = "dev"
  *   }
  * }
  * ```
  * 
  * ## External NAT Gateway IPs
  * 
  * By default this module will provision new Elastic IPs for the VPC's NAT Gateways.
  * This means that when creating a new VPC, new IPs are allocated, and when that VPC is destroyed those IPs are released.
  * Sometimes it is handy to keep the same IPs even after the VPC is destroyed and re-created.
  * To that end, it is possible to assign existing IPs to the NAT Gateways.
  * This prevents the destruction of the VPC from releasing those IPs, while making it possible that a re-created VPC uses the same IPs.
  * 
  * To achieve this, allocate the IPs outside the VPC module declaration.
  * ```hcl
  * resource "aws_eip" "nat" {
  *   count = 3
  * 
  *   vpc = true
  * }
  * ```
  * 
  * Then, pass the allocated IPs as a parameter to this module.
  * ```hcl
  * module "vpc" {
  *   source = "104corp/vpc/aws"
  * 
  *   # The rest of arguments are omitted for brevity
  * 
  *   enable_nat_gateway  = true
  *   single_nat_gateway  = false
  *   reuse_nat_ips       = true                      # <= Skip creation of EIPs for the NAT Gateways
  *   external_nat_ip_ids = ["${aws_eip.nat.*.id}"]   # <= IPs specified here as input to the module
  * }
  * ```
  * 
  * Note that in the example we allocate 3 IPs because we will be provisioning 3 NAT Gateways (due to `single_nat_gateway = false` and having 3 subnets).
  * If, on the other hand, `single_nat_gateway = true`, then `aws_eip.nat` would only need to allocate 1 IP.
  * Passing the IPs into the module is done by setting two variables `reuse_nat_ips = true` and `external_nat_ip_ids = ["${aws_eip.nat.*.id}"]`.
  * 
  * ## NAT Gateway Scenarios
  * 
  * This module supports three scenarios for creating NAT gateways. Each will be explained in further detail in the corresponding sections.
  * 
  * * One NAT Gateway per subnet (default behavior)
  *     * `enable_nat_gateway = true`
  *     * `single_nat_gateway = false`
  *     * `one_nat_gateway_per_az = false`
  * * Single NAT Gateway
  *     * `enable_nat_gateway = true`
  *     * `single_nat_gateway = true`
  *     * `one_nat_gateway_per_az = false`
  * * One NAT Gateway per availability zone
  *     * `enable_nat_gateway = true`
  *     * `single_nat_gateway = false`
  *     * `one_nat_gateway_per_az = true`
  * 
  * If both `single_nat_gateway` and `one_nat_gateway_per_az` are set to `true`, then `single_nat_gateway` takes precedence.
  * 
  * ### One NAT Gateway per subnet (default)
  * 
  * By default, the module will determine the number of NAT Gateways to create based on the the `max()` of the private subnet lists.
  * 
  * ```hcl
  * private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
  * public_subnets    = ["10.0.41.0/24", "10.0.42.0/24"]
  * nat_subnets       = ["10.0.51.0/24", "10.0.52.0/24", "10.0.53.0/24"]
  * ```
  * 
  * Then `3` NAT Gateways will be created since `3` private subnet CIDR blocks were specified.
  * 
  * ### Single NAT Gateway
  * 
  * If `single_nat_gateway = true`, then all private subnets will route their Internet traffic through this single NAT gateway. The NAT gateway will be placed in the first public subnet in your `public_subnets` block.
  * 
  * ### One NAT Gateway per availability zone
  * 
  * If `one_nat_gateway_per_az = true` and `single_nat_gateway = false`, then the module will place one NAT gateway in each availability zone you specify in `var.azs`. There are some requirements around using this feature flag:
  * 
  * * The variable `var.azs` **must** be specified.
  * * The number of public subnet CIDR blocks specified in `public_subnets` **must** be greater than or equal to the number of availability zones specified in `var.azs`. This is to ensure that each NAT Gateway has a dedicated public subnet to deploy to.
  * 
  * ## Conditional creation
  * 
  * Sometimes you need to have a way to create VPC resources conditionally but Terraform does not allow to use `count` inside `module` block, so the solution is to specify argument `create_vpc`.
  * 
  * ```hcl
  * # This VPC will not be created
  * module "vpc" {
  *   source = "104corp/vpc/aws"
  * 
  *   create_vpc = false
  *   # ... omitted
  * }
  * ```
  * 
  * ## Terraform version
  * 
  * Terraform version 0.10.3 or newer is required for this module to work.
  * 
  * ## Examples
  * 
  * * [Simple VPC](https://github.com/104corp/terraform-aws-vpc/tree/master/examples/simple-vpc)
  * * [Complete VPC](https://github.com/104corp/terraform-aws-vpc/tree/master/examples/complete-vpc)
  * * [Manage Default VPC](https://github.com/104corp/terraform-aws-vpc/tree/master/examples/manage-default-vpc)
  * 
  * 
  * 
  * ## Tests
  * 
  * This module has been packaged with [awspec](https://github.com/k1LoW/awspec) tests through test kitchen. To run them:
  * 
  * 1. Install [rvm](https://rvm.io/rvm/install) and the ruby version specified in the [Gemfile](https://github.com/104corp/terraform-aws-vpc/blob/master/Gemfile).
  * 2. Install bundler and the gems from our Gemfile:
  * ```
  * gem install bundler; bundle install
  * ```
  * 3. Test using `bundle exec kitchen test` from the root of the repo.
  * 
  * 
  * ## Authors
  * 
  * Module is maintained by [104corp](https://github.com/104corp).
  * 
  * basic fork of [Anton Babenko](https://github.com/antonbabenko)
  * 
  * ## License
  * 
  * Apache 2 Licensed. See LICENSE for full details.
  */

terraform {
  required_version = ">= 0.10.3" # introduction of Local Values configuration language feature
}

locals {
  max_subnet_length = "${length(var.private_subnets)}"
  nat_gateway_count = "${var.single_nat_gateway ? 1 : (var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length)}"

  # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = "${element(concat(aws_vpc_ipv4_cidr_block_association.this.*.vpc_id, aws_vpc.this.*.id, list("")), 0)}"
}

######
# VPC
######
resource "aws_vpc" "this" {
  count = "${var.create_vpc ? 1 : 0}"

  cidr_block                       = "${var.cidr}"
  instance_tenancy                 = "${var.instance_tenancy}"
  enable_dns_hostnames             = "${var.enable_dns_hostnames}"
  enable_dns_support               = "${var.enable_dns_support}"
  assign_generated_ipv6_cidr_block = "${var.assign_generated_ipv6_cidr_block}"

  tags = "${merge(map("Name", format("%s", var.name)), var.vpc_tags, var.tags)}"
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = "${var.create_vpc && length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0}"

  vpc_id = "${aws_vpc.this.id}"

  cidr_block = "${element(var.secondary_cidr_blocks, count.index)}"
}

###################
# DHCP Options Set
###################
resource "aws_vpc_dhcp_options" "this" {
  count = "${var.create_vpc && var.enable_dhcp_options ? 1 : 0}"

  domain_name          = "${var.dhcp_options_domain_name}"
  domain_name_servers  = ["${var.dhcp_options_domain_name_servers}"]
  ntp_servers          = ["${var.dhcp_options_ntp_servers}"]
  netbios_name_servers = ["${var.dhcp_options_netbios_name_servers}"]
  netbios_node_type    = "${var.dhcp_options_netbios_node_type}"

  tags = "${merge(map("Name", format("%s", var.name)), var.dhcp_options_tags, var.tags)}"
}

###############################
# DHCP Options Set Association
###############################
resource "aws_vpc_dhcp_options_association" "this" {
  count = "${var.create_vpc && var.enable_dhcp_options ? 1 : 0}"

  vpc_id          = "${local.vpc_id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.this.id}"
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "this" {
  count = "${var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = "${local.vpc_id}"

  tags = "${merge(map("Name", format("%s", var.name)), var.igw_tags, var.tags)}"
}

################
# Publiс routes
################
resource "aws_route_table" "public" {
  count = "${var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_id = "${local.vpc_id}"

  tags = "${merge(map("Name", format("%s-public", var.name)), var.public_route_table_tags, var.tags)}"
}

resource "aws_route" "public_internet_gateway" {
  count = "${var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0}"

  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.this.id}"

  timeouts {
    create = "5m"
  }
}

#################
# Private routes
# There are so many routing tables as the largest amount of subnets of each type (really?)
#################
resource "aws_route_table" "private" {
  count = "${var.create_vpc && local.max_subnet_length > 0 ? local.nat_gateway_count : 0}"

  vpc_id = "${local.vpc_id}"

  tags = "${merge(map("Name", (var.single_nat_gateway ? "${var.name}-private" : format("%s-private-%s", var.name, element(var.azs, count.index)))), var.private_route_table_tags, var.tags)}"

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = ["propagating_vgws"]
  }
}

#################
# NAT routes
#################
resource "aws_route_table" "nat" {
  count = "${var.create_vpc && length(var.nat_subnets) > 0 ? 1 : 0}"

  vpc_id = "${local.vpc_id}"

  tags = "${merge(map("Name", "${var.name}-nat"), var.nat_route_table_tags, var.tags)}"
}

################
# Public subnet
################
resource "aws_subnet" "public" {
  count = "${var.create_vpc && length(var.public_subnets) > 0 && (!var.one_nat_gateway_per_az || length(var.public_subnets) >= length(var.azs)) ? length(var.public_subnets) : 0}"

  vpc_id                  = "${local.vpc_id}"
  cidr_block              = "${var.public_subnets[count.index]}"
  availability_zone       = "${element(var.azs, count.index)}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"

  tags = "${merge(map("Name", format("%s-public-%s", var.name, element(var.azs, count.index))), var.public_subnet_tags, var.tags)}"
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count = "${var.create_vpc && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0}"

  vpc_id            = "${local.vpc_id}"
  cidr_block        = "${var.private_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"

  tags = "${merge(map("Name", format("%s-private-%s", var.name, element(var.azs, count.index))), var.private_subnet_tags, var.tags)}"
}

#####################################################
# NAT subnets - private subnet with NAT gateway
#####################################################
resource "aws_subnet" "nat" {
  count = "${var.create_vpc && length(var.nat_subnets) > 0 ? length(var.nat_subnets) : 0}"

  vpc_id            = "${local.vpc_id}"
  cidr_block        = "${var.nat_subnets[count.index]}"
  availability_zone = "${element(var.azs, count.index)}"

  tags = "${merge(map("Name", format("%s-nat-%s", var.name, element(var.azs, count.index))), var.nat_subnet_tags, var.tags)}"
}

##############
# NAT Gateway
##############
# Workaround for interpolation not being able to "short-circuit" the evaluation of the conditional branch that doesn't end up being used
# Source: https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
#
# The logical expression would be
#
#    nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat.*.id
#
# but then when count of aws_eip.nat.*.id is zero, this would throw a resource not found error on aws_eip.nat.*.id.
locals {
  nat_gateway_ips = "${split(",", (var.reuse_nat_ips ? join(",", var.external_nat_ip_ids) : join(",", aws_eip.nat.*.id)))}"
}

resource "aws_eip" "nat" {
  count = "${var.create_vpc && !var.reuse_nat_ips && length(var.nat_subnets) > 0 ? local.nat_gateway_count : 0}"

  vpc = true

  tags = "${merge(map("Name", format("%s-%s", var.name, element(var.azs, (var.single_nat_gateway ? 0 : count.index)))), var.nat_eip_tags, var.tags)}"
}

resource "aws_nat_gateway" "this" {
  count = "${var.create_vpc && length(var.nat_subnets) > 0 ? local.nat_gateway_count : 0}"

  allocation_id = "${element(local.nat_gateway_ips, (var.single_nat_gateway ? 0 : count.index))}"
  subnet_id     = "${element(aws_subnet.public.*.id, (var.single_nat_gateway ? 0 : count.index))}"

  tags = "${merge(map("Name", format("%s-%s", var.name, element(var.azs, (var.single_nat_gateway ? 0 : count.index)))), var.nat_gateway_tags, var.tags)}"

  depends_on = ["aws_internet_gateway.this"]
}

##########################
# Route table association
##########################
resource "aws_route_table_association" "private" {
  count = "${var.create_vpc && length(var.private_subnets) > 0 ? length(var.private_subnets) : 0}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, (var.single_nat_gateway ? 0 : count.index))}"
}

resource "aws_route_table_association" "nat" {
  count = "${var.create_vpc && length(var.nat_subnets) > 0 ? length(var.nat_subnets) : 0}"

  subnet_id      = "${element(aws_subnet.nat.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.nat.*.id, 0)}"
}

resource "aws_route_table_association" "public" {
  count = "${var.create_vpc && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

##############
# VPN Gateway
##############
resource "aws_vpn_gateway" "this" {
  count = "${var.create_vpc && var.enable_vpn_gateway ? 1 : 0}"

  vpc_id = "${aws_vpc.this.id}"

  tags = "${merge(map("Name", format("%s", var.name)), var.vpn_gateway_tags, var.tags)}"
}

resource "aws_vpn_gateway_attachment" "this" {
  count = "${var.vpn_gateway_id != "" ? 1 : 0}"

  vpc_id         = "${aws_vpc.this.id}"
  vpn_gateway_id = "${var.vpn_gateway_id}"
}

resource "aws_vpn_gateway_route_propagation" "public" {
  count = "${var.create_vpc && var.propagate_public_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? 1 : 0}"

  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
  vpn_gateway_id = "${element(concat(aws_vpn_gateway.this.*.id, aws_vpn_gateway_attachment.this.*.vpn_gateway_id), count.index)}"
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count = "${var.create_vpc && var.propagate_private_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? length(var.private_subnets) : 0}"

  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  vpn_gateway_id = "${element(concat(aws_vpn_gateway.this.*.id, aws_vpn_gateway_attachment.this.*.vpn_gateway_id), count.index)}"
}

###########
# Defaults
###########
resource "aws_default_vpc" "this" {
  count = "${var.manage_default_vpc ? 1 : 0}"

  enable_dns_support   = "${var.default_vpc_enable_dns_support}"
  enable_dns_hostnames = "${var.default_vpc_enable_dns_hostnames}"
  enable_classiclink   = "${var.default_vpc_enable_classiclink}"

  tags = "${merge(map("Name", format("%s", var.default_vpc_name)), var.default_vpc_tags, var.tags)}"
}
