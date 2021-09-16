output "recovery_kms_arn" {
	value = aws_kms_key.recovery.arn
}

output "boundary_url" {
	value = aws_route53_record.this.fqdn
}