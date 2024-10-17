data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "wordpress" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.allow_http.id]
  key_name                    = aws_key_pair.deployer.key_name
  subnet_id                   = aws_subnet.pub-a.id
  associate_public_ip_address = true
  user_data                   = file("${path.module}/apache.sh")
  tags = {
    Name = "wordpress"
  }
}

