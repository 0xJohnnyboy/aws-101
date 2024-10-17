resource "aws_route_table" "cesi-rt" {
  vpc_id = aws_vpc.cesi.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "cesi-rt"
  }
}

resource "aws_route_table_association" "pub-a" {
  subnet_id      = aws_subnet.pub-a.id
  route_table_id = aws_route_table.cesi-rt.id
}

resource "aws_route_table_association" "pub-b" {
  subnet_id      = aws_subnet.pub-b.id
  route_table_id = aws_route_table.cesi-rt.id
}