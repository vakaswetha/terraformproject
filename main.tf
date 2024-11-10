provider "aws" {
  region = "ap-south-1"
}
resource "aws_vpc" "main" {
  cidr_block       = var.cidr
  instance_tenancy = "default"
  tags = {
    Name = "vpc"
  }
}
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr1
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    name = "public_subnet1"
  }
}
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.cidr2
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    name = "public_subnet2"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    name = "igw"
  }
}
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}
resource "aws_security_group" "sg" {
  name   = "sg webserver"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_s3_bucket" "example" {
  bucket = "swethas3bucket1518"
}
resource "aws_instance" "webserver-1" {
  ami                    = "ami-08bf489a05e916bbd"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sub1.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = base64encode(file("userdata.sh"))
}
resource "aws_instance" "webserver-2" {
  ami                    = "ami-08bf489a05e916bbd"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sub2.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data              = base64encode(file("userdata1.sh"))
}
#create lb
resource "aws_lb" "lb1" {
name               = "loadbalancer"
internal           = false
load_balancer_type = "application"
security_groups    = [aws_security_group.sg.id]
subnets            = ["aws_subnet.sub1" , "aws_subnet.sub2"]
}
resource "aws_lb_target_group" "tg" {
  name        = "targetgroup"
  target_type = "alb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id

  health_check {
    path = "/"
    port = 80
  }
}
resource "aws_lb_target_group_attachment" "tg1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver-1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "tg2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver-2.id
  port             = 80
}
resource "aws_lb_listener" "pt1" {
  load_balancer_arn = aws_lb.lb1.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
} 


