variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = ""
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  default     = ""
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  default     = "default"
}

variable "enable_dns_hostnames" {
  description = "should be true if you want to use private DNS within the VPC"
  default     = false
}

variable "enable_dns_support" {
  description = "should be true if you want to use private DNS within the VPC"
  default     = false
}

variable "public_azs" {
  description = "A list of Public Availability zones in the region"
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  default     = []
}

variable "public_footer" {
  description = "A list of Public tags footer"
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "should be false if you do not want to auto-assign public IP on launch"
  default     = true
}

variable "private_azs" {
  description = "A list of Private Availability zones in the region"
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  default     = []
}

variable "private_footer" {
  description = "A list of Private tags footer"
  default     = []
}

variable "private_route_cidr" {
  description = "A list of private route CIDR inside the Route Table"
  default     = []
}

variable "private_route_eni" {
  description = "A list of private route target Network Interface ID inside the Route Table"
  default     = []
}

variable "private_route_instance" {
  description = "A list of private route target Instance ID inside the Route Table"
  default     = []
}

variable "private_route_gw" {
  description = "A list of private route target Internet Gateway or a Virtual Private Gateway inside the Route Table"
  default     = []
}

variable "nat_azs" {
  description = "A list of NAT Availability zones in the region"
  default     = []
}

variable "nat_subnets" {
  description = "A list of NAT subnets inside the VPC"
  default     = []
}

variable "nat_footer" {
  description = "A list of NAT tags footer"
  default     = []
}

variable "nat_route_cidr" {
  description = "A list of NAT route CIDR inside the Route Table"
  default     = []
}

variable "nat_route_eni" {
  description = "A list of NAT route target Network Interface ID inside the Route Table"
  default     = []
}

variable "nat_route_instance" {
  description = "A list of NAT route target Instance ID inside the Route Table"
  default     = []
}

variable "nat_route_gw" {
  description = "A list of NAT route target Internet Gateway or a Virtual Private Gateway inside the Route Table"
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "public_propagating_vgws" {
  description = "A list of VGWs the Public route table should propagate"
  default     = []
}

variable "private_propagating_vgws" {
  description = "A list of VGWs the Private route table should propagate"
  default     = []
}

variable "nat_propagating_vgws" {
  description = "A list of VGWs the NAT route table should propagate"
  default     = []
}

variable "enable_nat_gateway" {
  description = "should be true if you want to provision NAT Gateways for each of your private networks"
  default     = true
}

variable "single_nat_gateway" {
  description = "should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  default     = false
}

variable "dhcp_options" {
  description = "should be true if you want to provision a DHCP Options of your VPC"
  default     = false
}

variable "domain_name" {
  description = "should be true if you want to provision a domain_name of your DHCP"
  default     = ""
}

variable "domain_name_servers" {
  description = "should be true if you want to provision domain_name_servers of your DHCP"
  default     = []
}

variable "ntp_servers" {
  description = "should be true if you want to provision ntp_servers of your DHCP"
  default     = []
}

variable "netbios_name_servers" {
  description = "should be true if you want to provision netbios_name_servers of your DHCP"
  default     = []
}

variable "netbios_node_type" {
  description = "should be true if you want to provision netbios_name_servers of your DHCP"
  default     = ""
}
