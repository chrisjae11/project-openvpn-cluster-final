provider "aws" {
  region = "${var.aws_region}"
}

provider "aws" {
  alias = "east-1"
  region = "us-east-1"
}
