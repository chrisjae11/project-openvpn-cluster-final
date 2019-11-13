variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "aws_region" {
  default = "us-west-2"
}

variable "delegation_set" {}

variable "private_key" {
  default = "mykey"
}

variable "public_key" {
  default = "mykey.pub"
}

variable "eip_count" {
  default = 2
}

variable "amis" {
  type = "map"

  default = {
    us-east-1 = "ami-13be557e"
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-844e0bf7"
  }
}

variable "domain_name" {
  default = "logicflux.tech"
}

variable "asg_max" {
  default = "4"
}

variable "asg_min" {
  default = "1"
}

variable "asg_cap" {
  default = "2"
}

variable "asg_grace" {
  default = "300"
}

variable "lc_instance_type" {
  default = "t2.small"
}

variable "asg_hct" {
  default = "ELB"
}

variable "channel" {
  default = "vpn-alarm"
}

variable "username" {
  default = "aws"
}
variable "slack_url" {}

variable "account_id" {}
