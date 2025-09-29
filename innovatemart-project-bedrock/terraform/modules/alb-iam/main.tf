data "aws_caller_identity" "current" {}

data "http" "alb_controller_policy" {
	url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
	name        = "${var.cluster_name}-alb-controller-policy"
	description = "IAM policy for AWS Load Balancer Controller"
	policy      = data.http.alb_controller_policy.response_body
}

data "aws_iam_policy_document" "alb_trust" {
	statement {
		effect  = "Allow"
		actions = ["sts:AssumeRoleWithWebIdentity"]

		principals {
			type        = "Federated"
			identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.oidc_host}"]
		}

		condition {
			test     = "StringEquals"
			variable = "${var.oidc_host}:sub"
			values   = ["system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"]
		}
	}
}

resource "aws_iam_role" "alb_controller" {
	name               = "${var.cluster_name}-alb-controller-role"
	assume_role_policy = data.aws_iam_policy_document.alb_trust.json
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
	role       = aws_iam_role.alb_controller.name
	policy_arn = aws_iam_policy.alb_controller.arn
}

output "role_arn" {
	description = "IAM role ARN for ALB controller"
	value       = aws_iam_role.alb_controller.arn
}
