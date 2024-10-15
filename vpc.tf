resource "aws_vpc" "cesi" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "cesi"
  }
}

