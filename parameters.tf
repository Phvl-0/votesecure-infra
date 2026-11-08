resource "aws_ssm_parameter" "secret" {
  for_each = toset([
    "POSTGRES_PASSWORD",
    "SECRET_KEY",
    "GHCR_TOKEN",
    "GRAFANA_ADMIN_PASSWORD",
  ])

  name  = "/votesecure/${each.key}"
  type  = "SecureString"
  value = "CHANGE_ME"

  lifecycle {
    ignore_changes = [value]
  }
}
