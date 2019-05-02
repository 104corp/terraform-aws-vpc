######################
# VPC Endpoint for S3
######################
data "aws_vpc_endpoint_service" "s3" {
  count = "${var.create_vpc && var.enable_s3_endpoint ? 1 : 0}"

  service = "s3"
}

resource "aws_vpc_endpoint" "s3" {
  count = "${var.create_vpc && var.enable_s3_endpoint ? 1 : 0}"

  vpc_id       = "${local.vpc_id}"
  service_name = "${data.aws_vpc_endpoint_service.s3.service_name}"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count = "${var.create_vpc && var.enable_s3_endpoint && length(var.private_subnets) > 0 ? 1 : 0}"

  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
  route_table_id  = "${element(aws_route_table.private.*.id, 0)}"
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  count = "${var.create_vpc && var.enable_s3_endpoint && length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
  route_table_id  = "${aws_route_table.public.id}"
}

############################
# VPC Endpoint for DynamoDB
############################
data "aws_vpc_endpoint_service" "dynamodb" {
  count = "${var.create_vpc && var.enable_dynamodb_endpoint ? 1 : 0}"

  service = "dynamodb"
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = "${var.create_vpc && var.enable_dynamodb_endpoint ? 1 : 0}"

  vpc_id       = "${local.vpc_id}"
  service_name = "${data.aws_vpc_endpoint_service.dynamodb.service_name}"
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb" {
  count = "${var.create_vpc && var.enable_dynamodb_endpoint && length(var.private_subnets) > 0 ? 1 : 0}"

  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
  route_table_id  = "${element(aws_route_table.private.*.id, 0)}"
}

resource "aws_vpc_endpoint_route_table_association" "public_dynamodb" {
  count = "${var.create_vpc && var.enable_dynamodb_endpoint && length(var.public_subnets) > 0 ? 1 : 0}"

  vpc_endpoint_id = "${aws_vpc_endpoint.dynamodb.id}"
  route_table_id  = "${aws_route_table.public.id}"
}

######################
# VPC Endpoint for SSM
######################
data "aws_vpc_endpoint_service" "ssm" {
  count = "${var.create_vpc && var.enable_ssm_endpoint ? 1 : 0}"

  service = "ssm"
}

resource "aws_vpc_endpoint" "ssm" {
  count = "${var.create_vpc && var.enable_ssm_endpoint ? 1 : 0}"

  vpc_id            = "${local.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.ssm.service_name}"
  vpc_endpoint_type = "Interface"

  security_group_ids  = ["${aws_security_group.ssm.id}", "${var.ssm_endpoint_security_group_ids}"]
  subnet_ids          = ["${coalescelist(var.ssm_endpoint_subnet_ids, aws_subnet.private.*.id)}"]
  private_dns_enabled = "${var.ssm_endpoint_private_dns_enabled}"
}

resource "aws_security_group" "ssm" {
  count = "${var.create_vpc && var.enable_ssm_endpoint ? 1 : 0}"

  name_prefix = "vpc-endpoint-ssm-"
  description = "SSM VPC Endpoint Security Group"
  vpc_id      = "${local.vpc_id}"
}

resource "aws_security_group_rule" "vpc_endpoint_ssm_https" {
  count = "${var.create_vpc && var.enable_ssm_endpoint ? 1 : 0}"

  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = "${aws_security_group.ssm.id}"
}

###############################
# VPC Endpoint for SSMMESSAGES
###############################
data "aws_vpc_endpoint_service" "ssmmessages" {
  count = "${var.create_vpc && var.enable_ssmmessages_endpoint ? 1 : 0}"

  service = "ssmmessages"
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count = "${var.create_vpc && var.enable_ssmmessages_endpoint ? 1 : 0}"

  vpc_id            = "${local.vpc_id}"
  service_name      = "${data.aws_vpc_endpoint_service.ssmmessages.service_name}"
  vpc_endpoint_type = "Interface"

  security_group_ids  = ["${aws_security_group.ssmmessages.id}", "${var.ssmmessages_endpoint_security_group_ids}"]
  subnet_ids          = ["${coalescelist(var.ssmmessages_endpoint_subnet_ids, aws_subnet.private.*.id)}"]
  private_dns_enabled = "${var.ssmmessages_endpoint_private_dns_enabled}"
}

resource "aws_security_group" "ssmmessages" {
  count = "${var.create_vpc && var.enable_ssmmessages_endpoint ? 1 : 0}"

  name_prefix = "vpc-endpoint-ssm-messages-"
  description = "SSM MESSAGES VPC Endpoint Security Group"
  vpc_id      = "${local.vpc_id}"
}

resource "aws_security_group_rule" "vpc_endpoint_ssm_messages_https" {
  count = "${var.create_vpc && var.enable_ssmmessages_endpoint ? 1 : 0}"

  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = "${aws_security_group.ssmmessages.id}"
}
