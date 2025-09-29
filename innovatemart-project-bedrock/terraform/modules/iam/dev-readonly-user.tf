resource "aws_iam_user" "dev_readonly_user" {
  name = var.iam_user_name
}

resource "aws_iam_access_key" "dev_readonly_user_access_key" {
  user = aws_iam_user.dev_readonly_user.name
}

# Attach the shared read-only policy defined in policies.tf
resource "aws_iam_user_policy_attachment" "attach_shared_readonly" {
  user       = aws_iam_user.dev_readonly_user.name
  policy_arn = aws_iam_policy.readonly_policy.arn
}