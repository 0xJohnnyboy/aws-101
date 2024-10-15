resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.cesi.id

  tags = {
    Name = "cesi-gw"
  }
}