resource "aws_ssm_parameter" "secret" {
  #checkov:skip=CKV_AWS_337:Default AWS-managed key encrypts the secrets; a customer-managed key adds a monthly cost
  for_each = toset([
    "POSTGRES_PASSWORD",
    "SECRET_KEY",
    "GHCR_TOKEN",
    "GRAFANA_ADMIN_PASSWORD",
    "TELEGRAM_BOT_TOKEN",
    "TELEGRAM_CHAT_ID",
  ])

  name  = "/votesecure/${each.key}"
  type  = "SecureString"
  value = "CHANGE_ME"

  lifecycle {
    ignore_changes = [value]
  }
}
