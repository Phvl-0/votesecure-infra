output "ci_deploy_role_arn" {
  value = aws_iam_role.ci_deploy.arn
}

output "public_ip" {
  value = aws_eip.main.public_ip
}

output "instance_id" {
  value = aws_instance.main.id
}
