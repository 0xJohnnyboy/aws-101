# PUBLIC
resource "aws_subnet" "pub-a" {
  vpc_id     = aws_vpc.cesi.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "pub-a"
  }
}

resource "aws_subnet" "pub-b" {
  vpc_id     = aws_vpc.cesi.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "pub-b"
  }
}

# PRIVATE
resource "aws_subnet" "priv-a" {
  vpc_id     = aws_vpc.cesi.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "priv-a"
  }
}

resource "aws_subnet" "priv-b" {
  vpc_id     = aws_vpc.cesi.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "priv-b"
  }
}

# DB
resource "aws_db_subnet_group" "cesi-db-sn" {
  name       = "main"
  subnet_ids = [aws_subnet.priv-a.id, aws_subnet.priv-b.id]

  tags = {
    Name = "cesi-db-subnet"
  }
}
