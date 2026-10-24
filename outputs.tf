output "instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "IP publica del servidor"
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "URL para abrir en el navegador"
  value       = "http://${aws_instance.web.public_ip}"
}