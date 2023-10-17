variable "awsprops" {
    type = map
    default = {
    region = "ap-south-1"
    vpc = "vpc-0614c45ad5b0cb2a4"
    ami = "ami-0f5ee92e2d63afc18"
    itype = "t2.micro"
    subnet = "subnet-01f61a534157f884e"
    publicip = true
    keyname = "lyerva-test1"
    secgroupname = "lyerva-devops-sg"
  }
}

provider "aws" {
  region = lookup(var.awsprops, "region")
}

resource "aws_security_group" "lyerva-devops-sg" {
  name = lookup(var.awsprops, "secgroupname")
  description = lookup(var.awsprops, "secgroupname")
  vpc_id = lookup(var.awsprops, "vpc")

  // To Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  // To Allow Port 80 Transport
  ingress {
    from_port = 80
    protocol = "6"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  // To Allow Port 80 Transport
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_instance" "lyerva-devops-ec2-ubuntu" {
  ami = lookup(var.awsprops, "ami")
  instance_type = lookup(var.awsprops, "itype")
  subnet_id = lookup(var.awsprops, "subnet") #FFXsubnet2
  associate_public_ip_address = lookup(var.awsprops, "publicip")
  key_name = lookup(var.awsprops, "keyname")


  vpc_security_group_ids = [
    aws_security_group.lyerva-devops-sg.id
  ]
  root_block_device {
    delete_on_termination = true
    volume_size = 50
    volume_type = "gp2"
  }
  tags = {
    Name ="SERVER01"
    Environment = "DEV"
    OS = "UBUNTU"
    Managed = "LYERVA"
  }

  depends_on = [ aws_security_group.lyerva-devops-sg ]
}
resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "ansible-playbook /Users/lyerva/Documents/DEVOPS/ANSIBLE/test-playbook.yml"
  }
}
output "ec2instance" {
  value = aws_instance.lyerva-devops-ec2-ubuntu.public_ip
}

