resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_private_key_pem" {
  filename          = "${path.module}/id_rsa"
  sensitive_content = tls_private_key.global_key.private_key_pem
  file_permission   = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Temporary key pair used for SSH accesss
resource "aws_key_pair" "ec2_key_pair" {
  key_name_prefix = "ec2-"
  public_key      = tls_private_key.global_key.public_key_openssh
}

# Security group to allow all traffic
resource "aws_security_group" "ec2_sg_allow_ssh" {
  name        = "ec2_sg_allow_ssh"
  description = "EC2 allow ssh access."

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Creator = "helm2-ec2"
  }
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.ec2_sg_allow_ssh.name]
  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [
      "echo 'install helm2 ...'",
      "curl -LO https://git.io/get_helm.sh",
      "chmod 700 get_helm.sh",
      "./get_helm.sh",
      "echo 'helm installed'",
      "echo 'install google cloud sdk",
      "curl https://sdk.cloud.google.com | bash",
      "echo 'google cloud sdk installed"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  tags = {
    Name = "helm2-playground"
  }
}