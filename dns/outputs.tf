# Hosted zone identifier
output "zone_id" {
  description = "Identifier of the public hosted zone for the root domain"
  value       = aws_route53_zone.main.zone_id
}

# Name server records for the root domain
output "name_servers" {
  description = "Name servers assigned to the hosted zone"
  value       = aws_route53_zone.main.name_servers
}
