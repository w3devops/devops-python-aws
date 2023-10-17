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
    secgroupname = "lyerva-devops-sg2"
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
output "ec2instanceip" {
  value = aws_instance.lyerva-devops-ec2-ubuntu.public_ip
}
resource "null_resource" "copyFile" {
  provisioner "file" {
    connection {
    host        = aws_instance.lyerva-devops-ec2-ubuntu.public_ip
    user        = "ubuntu"
    type        = "ssh"
    private_key = "${file("/Users/lyerva/Documents/DEVOPS/ANSIBLE/lyerva-test1.pem")}"
    timeout     = "2m"
    agent       = "false"
   }
    source      = "/Users/lyerva/Documents/DEVOPS/ANSIBLE/test-playbook.yml"
    destination = "/tmp/test-playbook.yml"
    
}
}
resource "null_resource" "execAnsiblePlaybook" {
  provisioner "remote-exec" {
  connection {
    host        = aws_instance.lyerva-devops-ec2-ubuntu.public_ip
    user        = "ubuntu"
    type        = "ssh"
    private_key = "${file("/Users/lyerva/Documents/DEVOPS/ANSIBLE/lyerva-test1.pem")}"
    timeout     = "2m"
    agent       = "false"
   }
  inline = [
      "sudo apt-get update",
      "sudo apt-get install ansible -y",
      "ansible-playbook /tmp/test-playbook.yml"
    ]
}
}

output "ec2instance" {
  value = aws_instance.lyerva-devops-ec2-ubuntu.public_ip
}

