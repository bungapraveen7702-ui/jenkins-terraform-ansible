output "public_ip" {
  description = "Public IP of EC2"
  value       = aws_instance.web_server.public_ip
}

output "instance_id" {
  value = aws_instance.web_server.id
}