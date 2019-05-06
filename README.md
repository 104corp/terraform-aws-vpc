# AWS VPC Terraform module

![Build Status](https://travis-ci.com/104corp/terraform-aws-vpc.svg?branch=master) ![LicenseBadge](https://img.shields.io/github/license/104corp/terraform-aws-vpc.svg)

Terraform module which creates VPC resources on AWS.

These types of resources are supported:

* [VPC](https://www.terraform.io/docs/providers/aws/r/vpc.html)
* [Subnet](https://www.terraform.io/docs/providers/aws/r/subnet.html)
* [Route](https://www.terraform.io/docs/providers/aws/r/route.html)
* [Route table](https://www.terraform.io/docs/providers/aws/r/route_table.html)
* [Internet Gateway](https://www.terraform.io/docs/providers/aws/r/internet_gateway.html)
* [NAT Gateway](https://www.terraform.io/docs/providers/aws/r/nat_gateway.html)
* [VPN Gateway](https://www.terraform.io/docs/providers/aws/r/vpn_gateway.html)
* [VPC Endpoint](https://www.terraform.io/docs/providers/aws/r/vpc_endpoint.html) (S3 and DynamoDB)
* [DHCP Options Set](https://www.terraform.io/docs/providers/aws/r/vpc_dhcp_options.html)
* [Default VPC](https://www.terraform.io/docs/providers/aws/r/default_vpc.html)

## Usage

```hcl
module "vpc" {
  source = "104corp/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c","ap-northeast-1d"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  nat_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
```

## External NAT Gateway IPs

By default this module will provision new Elastic IPs for the VPC's NAT Gateways.
This means that when creating a new VPC, new IPs are allocated, and when that VPC is destroyed those IPs are released.
Sometimes it is handy to keep the same IPs even after the VPC is destroyed and re-created.
To that end, it is possible to assign existing IPs to the NAT Gateways.
This prevents the destruction of the VPC from releasing those IPs, while making it possible that a re-created VPC uses the same IPs.

To achieve this, allocate the IPs outside the VPC module declaration.
```hcl
resource "aws_eip" "nat" {
  count = 3

  vpc = true
}
```

Then, pass the allocated IPs as a parameter to this module.
```hcl
module "vpc" {
  source = "104corp/vpc/aws"

  # The rest of arguments are omitted for brevity

  enable_nat_gateway  = true
  single_nat_gateway  = false
  reuse_nat_ips       = true                      # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = ["${aws_eip.nat.*.id}"]   # <= IPs specified here as input to the module
}
```

Note that in the example we allocate 3 IPs because we will be provisioning 3 NAT Gateways (due to `single_nat_gateway = false` and having 3 subnets).
If, on the other hand, `single_nat_gateway = true`, then `aws_eip.nat` would only need to allocate 1 IP.
Passing the IPs into the module is done by setting two variables `reuse_nat_ips = true` and `external_nat_ip_ids = ["${aws_eip.nat.*.id}"]`.

## NAT Gateway Scenarios

This module supports three scenarios for creating NAT gateways. Each will be explained in further detail in the corresponding sections.

* One NAT Gateway per subnet (default behavior)
    * `enable_nat_gateway = true`
    * `single_nat_gateway = false`
    * `one_nat_gateway_per_az = false`
* Single NAT Gateway
    * `enable_nat_gateway = true`
    * `single_nat_gateway = true`
    * `one_nat_gateway_per_az = false`
* One NAT Gateway per availability zone
    * `enable_nat_gateway = true`
    * `single_nat_gateway = false`
    * `one_nat_gateway_per_az = true`

If both `single_nat_gateway` and `one_nat_gateway_per_az` are set to `true`, then `single_nat_gateway` takes precedence.

### One NAT Gateway per subnet (default)

By default, the module will determine the number of NAT Gateways to create based on the the `max()` of the private subnet lists.

```hcl
private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
public_subnets    = ["10.0.41.0/24", "10.0.42.0/24"]
nat_subnets       = ["10.0.51.0/24", "10.0.52.0/24", "10.0.53.0/24"]
```

Then `3` NAT Gateways will be created since `3` private subnet CIDR blocks were specified.

### Single NAT Gateway

If `single_nat_gateway = true`, then all private subnets will route their Internet traffic through this single NAT gateway. The NAT gateway will be placed in the first public subnet in your `public_subnets` block.

### One NAT Gateway per availability zone

If `one_nat_gateway_per_az = true` and `single_nat_gateway = false`, then the module will place one NAT gateway in each availability zone you specify in `var.azs`. There are some requirements around using this feature flag:

* The variable `var.azs` **must** be specified.
* The number of public subnet CIDR blocks specified in `public_subnets` **must** be greater than or equal to the number of availability zones specified in `var.azs`. This is to ensure that each NAT Gateway has a dedicated public subnet to deploy to.

## Conditional creation

Sometimes you need to have a way to create VPC resources conditionally but Terraform does not allow to use `count` inside `module` block, so the solution is to specify argument `create_vpc`.

```hcl
# This VPC will not be created
module "vpc" {
  source = "104corp/vpc/aws"

  create_vpc = false
  # ... omitted
}
```

## Terraform version

Terraform version 0.10.3 or newer is required for this module to work.

## Examples

* [Simple VPC](https://github.com/104corp/terraform-aws-vpc/tree/master/examples/simple-vpc)
* [Complete VPC](https://github.com/104corp/terraform-aws-vpc/tree/master/examples/complete-vpc)
* [Manage Default VPC](https://github.com/104corp/terraform-aws-vpc/tree/master/examples/manage-default-vpc)

## Tests

This module has been packaged with [awspec](https://github.com/k1LoW/awspec) tests through test kitchen. To run them:

1. Install [rvm](https://rvm.io/rvm/install) and the ruby version specified in the [Gemfile](https://github.com/104corp/terraform-aws-vpc/blob/master/Gemfile).
2. Install bundler and the gems from our Gemfile:
```
gem install bundler; bundle install
```
3. Test using `bundle exec kitchen test` from the root of the repo.

## Authors

Module is maintained by [104corp](https://github.com/104corp).

basic fork of [Anton Babenko](https://github.com/antonbabenko)

## License

Apache 2 Licensed. See LICENSE for full details.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| assign\_generated\_ipv6\_cidr\_block | Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block | string | `"false"` | no |
| azs | A list of availability zones in the region | list | `<list>` | no |
| cidr | The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden | string | `"0.0.0.0/0"` | no |
| create\_vpc | Controls if VPC should be created (it affects almost all resources) | string | `"true"` | no |
| default\_network\_acl\_egress | List of maps of egress rules to set on the Default Network ACL | list | `<list>` | no |
| default\_network\_acl\_ingress | List of maps of ingress rules to set on the Default Network ACL | list | `<list>` | no |
| default\_network\_acl\_name | Name to be used on the Default Network ACL | string | `""` | no |
| default\_network\_acl\_tags | Additional tags for the Default Network ACL | map | `<map>` | no |
| default\_vpc\_enable\_classiclink | Should be true to enable ClassicLink in the Default VPC | string | `"false"` | no |
| default\_vpc\_enable\_dns\_hostnames | Should be true to enable DNS hostnames in the Default VPC | string | `"false"` | no |
| default\_vpc\_enable\_dns\_support | Should be true to enable DNS support in the Default VPC | string | `"true"` | no |
| default\_vpc\_name | Name to be used on the Default VPC | string | `""` | no |
| default\_vpc\_tags | Additional tags for the Default VPC | map | `<map>` | no |
| dhcp\_options\_domain\_name | Specifies DNS name for DHCP options set | string | `""` | no |
| dhcp\_options\_domain\_name\_servers | Specify a list of DNS server addresses for DHCP options set, default to AWS provided | list | `<list>` | no |
| dhcp\_options\_netbios\_name\_servers | Specify a list of netbios servers for DHCP options set | list | `<list>` | no |
| dhcp\_options\_netbios\_node\_type | Specify netbios node_type for DHCP options set | string | `""` | no |
| dhcp\_options\_ntp\_servers | Specify a list of NTP servers for DHCP options set | list | `<list>` | no |
| dhcp\_options\_tags | Additional tags for the DHCP option set | map | `<map>` | no |
| ec2\_endpoint\_private\_dns\_enabled | Whether or not to associate a private hosted zone with the specified VPC for EC2 endpoint | string | `"false"` | no |
| ec2\_endpoint\_security\_group\_ids | The ID of one or more security groups to associate with the network interface for EC2 endpoint | list | `<list>` | no |
| ec2\_endpoint\_subnet\_ids | The ID of one or more subnets in which to create a network interface for EC2 endpoint. Only a single subnet within an AZ is supported. If omitted, private subnets will be used. | list | `<list>` | no |
| ec2messages\_endpoint\_private\_dns\_enabled | Whether or not to associate a private hosted zone with the specified VPC for EC2 messages endpoint | string | `"false"` | no |
| ec2messages\_endpoint\_security\_group\_ids | The ID of one or more security groups to associate with the network interface for EC2 messages endpoint | list | `<list>` | no |
| ec2messages\_endpoint\_subnet\_ids | The ID of one or more subnets in which to create a network interface for EC2 messages endpoint. Only a single subnet within an AZ is supported. If omitted, private subnets will be used. | list | `<list>` | no |
| enable\_dhcp\_options | Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type | string | `"false"` | no |
| enable\_dns\_hostnames | Should be true to enable DNS hostnames in the VPC | string | `"false"` | no |
| enable\_dns\_support | Should be true to enable DNS support in the VPC | string | `"true"` | no |
| enable\_dynamodb\_endpoint | Should be true if you want to provision a DynamoDB endpoint to the VPC | string | `"false"` | no |
| enable\_ec2\_endpoint | Should be true if you want to provision an EC2 endpoint to the VPC | string | `"false"` | no |
| enable\_ec2messages\_endpoint | Should be true if you want to provision an EC2 messages endpoint to the VPC | string | `"false"` | no |
| enable\_s3\_endpoint | Should be true if you want to provision an S3 endpoint to the VPC | string | `"false"` | no |
| enable\_ssm\_endpoint | Should be true if you want to provision an SSM endpoint to the VPC | string | `"false"` | no |
| enable\_ssmmessages\_endpoint | Should be true if you want to provision a SSMMESSAGES endpoint to the VPC | string | `"false"` | no |
| enable\_vpn\_gateway | Should be true if you want to create a new VPN Gateway resource and attach it to the VPC | string | `"false"` | no |
| external\_nat\_ip\_ids | List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse_nat_ips) | list | `<list>` | no |
| igw\_tags | Additional tags for the internet gateway | map | `<map>` | no |
| instance\_tenancy | A tenancy option for instances launched into the VPC | string | `"default"` | no |
| manage\_default\_network\_acl | Should be true to adopt and manage Default Network ACL | string | `"false"` | no |
| manage\_default\_vpc | Should be true to adopt and manage Default VPC | string | `"false"` | no |
| map\_public\_ip\_on\_launch | Should be false if you do not want to auto-assign public IP on launch | string | `"true"` | no |
| name | Name to be used on all the resources as identifier | string | `""` | no |
| nat\_acl\_tags | Additional tags for the public subnets network ACL | map | `<map>` | no |
| nat\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for nat subnets | string | `"false"` | no |
| nat\_eip\_tags | Additional tags for the NAT EIP | map | `<map>` | no |
| nat\_gateway\_tags | Additional tags for the NAT gateways | map | `<map>` | no |
| nat\_inbound\_acl\_rules | NAT subnets inbound network ACLs | list | `<list>` | no |
| nat\_outbound\_acl\_rules | NAT subnets outbound network ACLs | list | `<list>` | no |
| nat\_route\_table\_tags | Additional tags for the intra route tables | map | `<map>` | no |
| nat\_subnet\_suffix | Suffix to append to NAT subnets name | string | `"nat"` | no |
| nat\_subnet\_tags | Additional tags for the intra subnets | map | `<map>` | no |
| nat\_subnets | A list of nat subnets | list | `<list>` | no |
| one\_nat\_gateway\_per\_az | Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`. | string | `"false"` | no |
| private\_acl\_tags | Additional tags for the public subnets network ACL | map | `<map>` | no |
| private\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for private subnets | string | `"false"` | no |
| private\_inbound\_acl\_rules | Private subnets inbound network ACLs | list | `<list>` | no |
| private\_outbound\_acl\_rules | Private subnets outbound network ACLs | list | `<list>` | no |
| private\_route\_table\_tags | Additional tags for the private route tables | map | `<map>` | no |
| private\_subnet\_suffix | Suffix to append to private subnets name | string | `"private"` | no |
| private\_subnet\_tags | Additional tags for the private subnets | map | `<map>` | no |
| private\_subnets | A list of private subnets inside the VPC | list | `<list>` | no |
| propagate\_private\_route\_tables\_vgw | Should be true if you want route table propagation | string | `"false"` | no |
| propagate\_public\_route\_tables\_vgw | Should be true if you want route table propagation | string | `"false"` | no |
| public\_acl\_tags | Additional tags for the public subnets network ACL | map | `<map>` | no |
| public\_dedicated\_network\_acl | Whether to use dedicated network ACL (not default) and custom rules for public subnets | string | `"false"` | no |
| public\_inbound\_acl\_rules | Public subnets inbound network ACLs | list | `<list>` | no |
| public\_outbound\_acl\_rules | Public subnets outbound network ACLs | list | `<list>` | no |
| public\_route\_table\_tags | Additional tags for the public route tables | map | `<map>` | no |
| public\_subnet\_suffix | Suffix to append to public subnets name | string | `"public"` | no |
| public\_subnet\_tags | Additional tags for the public subnets | map | `<map>` | no |
| public\_subnets | A list of public subnets inside the VPC | list | `<list>` | no |
| reuse\_nat\_ips | Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external_nat_ip_ids' variable | string | `"false"` | no |
| secondary\_cidr\_blocks | List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool | list | `<list>` | no |
| single\_nat\_gateway | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | string | `"false"` | no |
| ssm\_endpoint\_private\_dns\_enabled | Whether or not to associate a private hosted zone with the specified VPC for SSM endpoint | string | `"false"` | no |
| ssm\_endpoint\_security\_group\_ids | The ID of one or more security groups to associate with the network interface for SSM endpoint | list | `<list>` | no |
| ssm\_endpoint\_subnet\_ids | The ID of one or more subnets in which to create a network interface for SSM endpoint. Only a single subnet within an AZ is supported. If omitted, private subnets will be used. | list | `<list>` | no |
| ssmmessages\_endpoint\_private\_dns\_enabled | Whether or not to associate a private hosted zone with the specified VPC for SSMMESSAGES endpoint | string | `"false"` | no |
| ssmmessages\_endpoint\_security\_group\_ids | The ID of one or more security groups to associate with the network interface for SSMMESSAGES endpoint | list | `<list>` | no |
| ssmmessages\_endpoint\_subnet\_ids | The ID of one or more subnets in which to create a network interface for SSMMESSAGES endpoint. Only a single subnet within an AZ is supported. If omitted, private subnets will be used. | list | `<list>` | no |
| tags | A map of tags to add to all resources | map | `<map>` | no |
| vpc\_tags | Additional tags for the VPC | map | `<map>` | no |
| vpn\_gateway\_id | ID of VPN Gateway to attach to the VPC | string | `""` | no |
| vpn\_gateway\_tags | Additional tags for the VPN gateway | map | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| azs | List of AZs of the VPC |
| default\_network\_acl\_id | The ID of the default network ACL |
| default\_route\_table\_id | The ID of the default route table |
| default\_security\_group\_id | The ID of the security group created by default on VPC creation |
| default\_vpc\_cidr\_block | The CIDR block of the VPC |
| default\_vpc\_default\_network\_acl\_id | The ID of the default network ACL |
| default\_vpc\_default\_route\_table\_id | The ID of the default route table |
| default\_vpc\_default\_security\_group\_id | The ID of the security group created by default on VPC creation |
| default\_vpc\_enable\_dns\_hostnames | Whether or not the VPC has DNS hostname support |
| default\_vpc\_enable\_dns\_support | Whether or not the VPC has DNS support |
| default\_vpc\_id | The ID of the VPC |
| default\_vpc\_instance\_tenancy | Tenancy of instances spin up within VPC |
| default\_vpc\_main\_route\_table\_id | The ID of the main route table associated with this VPC |
| igw\_id | The ID of the Internet Gateway |
| nat\_ids | List of allocation ID of Elastic IPs created for AWS NAT Gateway |
| nat\_public\_ips | List of public Elastic IPs created for AWS NAT Gateway |
| nat\_route\_table\_ids | List of IDs of nat route tables |
| nat\_subnets | List of IDs of nat subnets |
| nat\_subnets\_cidr\_blocks | List of cidr_blocks of nat subnets |
| natgw\_ids | List of NAT Gateway IDs |
| private\_route\_table\_ids | List of IDs of private route tables |
| private\_subnets | List of IDs of private subnets |
| private\_subnets\_cidr\_blocks | List of cidr_blocks of private subnets |
| public\_route\_table\_ids | List of IDs of public route tables |
| public\_subnets | List of IDs of public subnets |
| public\_subnets\_cidr\_blocks | List of cidr_blocks of public subnets |
| vgw\_id | The ID of the VPN Gateway |
| vpc\_cidr\_block | The CIDR block of the VPC |
| vpc\_enable\_dns\_hostnames | Whether or not the VPC has DNS hostname support |
| vpc\_enable\_dns\_support | Whether or not the VPC has DNS support |
| vpc\_endpoint\_dynamodb\_id | The ID of VPC endpoint for DynamoDB |
| vpc\_endpoint\_dynamodb\_pl\_id | The prefix list for the DynamoDB VPC endpoint. |
| vpc\_endpoint\_s3\_id | The ID of VPC endpoint for S3 |
| vpc\_endpoint\_s3\_pl\_id | The prefix list for the S3 VPC endpoint. |
| vpc\_id | The ID of the VPC |
| vpc\_instance\_tenancy | Tenancy of instances spin up within VPC |
| vpc\_main\_route\_table\_id | The ID of the main route table associated with this VPC |

