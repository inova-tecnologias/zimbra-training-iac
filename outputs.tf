output "ssh_key" {
  description = "Key for access the vms"
  sensitive = true
  value = tls_private_key.training_pem.private_key_pem
}

output "dns_entries" {
    description = "Adresses for accessing training vms"
    value = concat(aws_route53_record.record_vm1.*.fqdn, aws_route53_record.record_vm2.*.fqdn)
}
