provider "aws" {
  region     = "ap-south-1"
  profile    = "amol"
}
variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default = "10.1.0.0/16"
}

variable "cidr_subnet1" {
  description = "CIDR block for the subnet"
  default = "10.1.0.0/24"
}


variable "cidr_subnet2" {
  description = "CIDR block for the subnet"
  default = "10.1.1.0/24"
}


variable "availability_zone" {
  description = "availability zone to create subnet"
  default = "ap-south-1"
}


variable "environment_tag" {
  description = "Environment tag"
  default = "Production"

}
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_vpc}"
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags ={
    Environment = "${var.environment_tag}"
    Name= "myvpc"
  }
}
resource "aws_subnet" "subnet_public1" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr_subnet1}"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1a"
  tags ={
    Environment = "${var.environment_tag}"
    Name= "mysubnet1"
  }

}
resource "aws_subnet" "subnet_private2" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr_subnet2}"
  map_public_ip_on_launch = "true"
  availability_zone = "ap-south-1a"
  tags ={
    Environment = "${var.environment_tag}"
    Name= "mysubnet2"
  }

}
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags ={
    Environment = "${var.environment_tag}"
    Name= "myinternetgateway"
  }

}
resource "aws_eip" "natlb" {
  vpc =true
}
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.natlb.id}"
  subnet_id     = "${aws_subnet.subnet_public1.id}"

  tags = {
    Name = "gw NAT"
  }
}



resource "aws_route_table" "rtb_public" {
  vpc_id = "${aws_vpc.vpc.id}"
route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.igw.id}"
  }
tags ={
    Environment = "${var.environment_tag}"
    Name= "myrouttable"
  }

}
resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = "${aws_subnet.subnet_public1.id}"
  route_table_id = "${aws_route_table.rtb_public.id}"
}
resource "aws_security_group" "sg_22" {
  name = "sg_22"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }


 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Environment = "${var.environment_tag}"
    Name= "mysg1"
  }

}
resource "aws_security_group" "sg_20" {
  name = "sg_20"
  description = "managed by terrafrom for mysql servers"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = ["${aws_security_group.sg_22.id}"]
  }


 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Environment = "${var.environment_tag}"
    Name= "mysg2"
  }

}
resource "aws_instance" "testInstance1" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet_public1.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_22.id}"]
  key_name = "terraformkey"
 tags ={
    Environment = "${var.environment_tag}"
    Name= "OS_wordpress"
  }

}
resource "aws_instance" "testInstance2" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.subnet_private2.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_20.id}"]
  key_name = "terraformkey"
 tags ={
    Environment = "${var.environment_tag}"
    Name= "OS_mysql"
  }
}