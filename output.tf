output ec2_public_ip {
  value       = aws_instance.main.public_ip
}
