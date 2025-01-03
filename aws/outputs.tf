output "private_dns" {
  value = aws_instance.instance.private_dns
}

# output "eip" {
#   value = aws_eip.example_ip.public_ip
# }
