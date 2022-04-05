output "id" {
  description = "The ID of the instance"
  value       = element(concat(aws_instance.main.*.id, [""]), 0)
}

output "arn" {
  description = "The ARN of the instance"
  value       = element(concat(aws_instance.main.*.arn, [""]), 0)
}

output "public_ip" {
  description = "The Public IP address of the instance"
  value = element(concat(aws_instance.main.*.public_ip, [""]), 0)
}

output "private_ip" {
  description = "The Private IP address of the instance"
  value = element(concat(aws_instance.main.*.private_ip, [""]), 0)
}
