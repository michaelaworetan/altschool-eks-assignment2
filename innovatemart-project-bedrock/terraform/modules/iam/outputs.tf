output "iam_user_arn" {
  value = aws_iam_user.dev_readonly_user.arn
}

output "iam_user_name" {
  value = aws_iam_user.dev_readonly_user.name
}

output "iam_user_access_key_id" {
  value = aws_iam_access_key.dev_readonly_user_access_key.id
}

output "iam_user_secret_access_key" {
  value     = aws_iam_access_key.dev_readonly_user_access_key.secret
  sensitive = true
}

output "iam_console_login_instructions" {
  value = "Create a console password for the IAM user and enable MFA. Access key/secret are output for programmatic access."
}