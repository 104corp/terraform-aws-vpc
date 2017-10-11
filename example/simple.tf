provider "aws" {
  region  = "ap-northeast-1"
}

module "vpc" {
  source = "../"

  name = "terraform-simple"

  cidr = "10.144.224.0/21"

  # public subnet
  public_subnets  = ["10.144.224.0/26","10.144.224.64/26"]
  public_azs      = ["ap-northeast-1a","ap-northeast-1c"]
  public_footer   = ["1a-1","1c-1"]

  # nat subnet
  nat_subnets     = ["10.144.224.128/26","10.144.224.192/26"]
  nat_azs         = ["ap-northeast-1a","ap-northeast-1c"]
  nat_footer      = ["1a-1","1c-1"]

  # private subnet
  private_subnets = ["10.144.225.0/24","10.144.226.0/24","10.144.227.0/24","10.144.228.0/24","10.144.229.0/24","10.144.230.0/24"]
  private_azs     = ["ap-northeast-1a","ap-northeast-1a","ap-northeast-1a","ap-northeast-1c","ap-northeast-1c","ap-northeast-1c"]
  private_footer  = ["1a-1","1a-2","1a-3","1c-1","1c-2","1c-3"]

  tags {
    Terraform = "true"
  }
}