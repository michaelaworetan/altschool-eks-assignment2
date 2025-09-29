locals {
  sa_namespace  = "kube-system"
  sa_name       = "aws-load-balancer-controller"
  oidc_host     = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

data "aws_caller_identity" "current" {}

data "http" "alb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

# Determine the VPC ID from one of the cluster subnets to avoid IMDS autodiscovery in the controller
data "aws_subnet" "cluster_subnet" {
  id = tolist(data.aws_eks_cluster.this.vpc_config[0].subnet_ids)[0]
}

# OIDC provider for the cluster
resource "aws_iam_policy" "alb_controller" {
  name        = "${local.operators_cluster_name}-alb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.alb_controller_policy.response_body
}

data "aws_iam_policy_document" "alb_trust" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_host}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:${local.sa_namespace}:${local.sa_name}"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${local.operators_cluster_name}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_trust.json
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubernetes_service_account" "alb_sa" {
  metadata {
    name      = local.sa_name
    namespace = local.sa_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
    labels = {
      "app.kubernetes.io/name"      = local.sa_name
      "app.kubernetes.io/component" = "controller"
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = local.sa_namespace
  version    = "1.8.1"

  # Allow extra time for the controller and its webhook service to become Ready
  timeout = 900
  cleanup_on_fail = true

  depends_on = [kubernetes_service_account.alb_sa, aws_iam_role_policy_attachment.alb_attach]

  values = [
    yamlencode({
      # Reduce controller replicas for single-node sandbox
      replicaCount  = 1
  clusterName   = local.operators_cluster_name
  region        = local.operators_region
      # Explicitly pass VPC ID to avoid EC2 metadata introspection in the controller
      vpcId        = data.aws_subnet.cluster_subnet.vpc_id
      serviceAccount = {
        create = false
        name   = local.sa_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
        }
      }
      enableServiceMutatorWebhook = true
      defaultTags   = {
        ManagedBy = "terraform"
  Stack     = local.operators_cluster_name
      }
    })
  ]
}

# --- ACM certificate for HTTPS (DNS validated in Route 53) ---
module "acm" {
  source = "../../modules/acm"
  count  = var.ingress_hostname != null && var.route53_zone_id != null ? 1 : 0

  domain_name         = var.ingress_hostname
  subject_alternative_names = []
  route53_zone_id     = var.route53_zone_id
  tags                = { Stack = local.operators_cluster_name }
}

output "ui_acm_certificate_arn" {
  description = "ACM certificate ARN for the UI HTTPS (null if hostname not set)"
  value       = try(module.acm[0].acm_certificate_arn, null)
}

# --- ExternalDNS: IRSA + Helm ---
locals {
  externaldns_namespace = "kube-system"
  externaldns_sa_name   = "external-dns"
}

data "aws_iam_policy_document" "externaldns_policy" {
  # Allow changes in the specific hosted zone
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = var.route53_zone_id != null ? [
      "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
    ] : ["*"]
  }

  # Read/list permissions required by external-dns
  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
      "route53:GetChange"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "externaldns" {
  count       = var.route53_zone_id != null ? 1 : 0
  name        = "${local.operators_cluster_name}-externaldns-policy"
  description = "IAM policy for ExternalDNS to manage Route 53"
  policy      = data.aws_iam_policy_document.externaldns_policy.json
}

data "aws_iam_policy_document" "externaldns_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_host}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:${local.externaldns_namespace}:${local.externaldns_sa_name}"]
    }
  }
}

resource "aws_iam_role" "externaldns" {
  count              = var.route53_zone_id != null ? 1 : 0
  name               = "${local.operators_cluster_name}-externaldns-role"
  assume_role_policy = data.aws_iam_policy_document.externaldns_trust.json
}

resource "aws_iam_role_policy_attachment" "externaldns_attach" {
  count      = var.route53_zone_id != null ? 1 : 0
  role       = aws_iam_role.externaldns[0].name
  policy_arn = aws_iam_policy.externaldns[0].arn
}

resource "kubernetes_service_account" "externaldns_sa" {
  count = var.route53_zone_id != null ? 1 : 0
  metadata {
    name      = local.externaldns_sa_name
    namespace = local.externaldns_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.externaldns[0].arn
    }
    labels = {
      "app.kubernetes.io/name" = "external-dns"
    }
  }
}

resource "helm_release" "externaldns" {
  count      = var.route53_zone_id != null ? 1 : 0
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = local.externaldns_namespace
  version    = "1.15.0"

  # Wait for ALB controller webhook to be available to avoid admission failures
  depends_on = [
    kubernetes_service_account.externaldns_sa,
    aws_iam_role_policy_attachment.externaldns_attach,
    helm_release.aws_load_balancer_controller
  ]

  timeout = 600
  cleanup_on_fail = true

  values = [
    yamlencode({
      serviceAccount = {
        create = false
        name   = local.externaldns_sa_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.externaldns[0].arn
        }
      }
      replicaCount = 1
      provider = "aws"
      policy   = "upsert-only"
      sources  = ["ingress"]
      domainFilters = var.ingress_hostname != null ? [regex("[^.]+\\.[^.]+$", var.ingress_hostname)] : []
      zoneIdFilters = [var.route53_zone_id]
      txtOwnerId    = local.operators_cluster_name
      registry      = "txt"
      txtPrefix     = "_externaldns."
      interval      = "1m"
      extraArgs     = ["--aws-zone-type=public"]
    })
  ]
}

# --- External Secrets Operator: IRSA + Helm ---
locals {
  eso_namespace = "kube-system"
  eso_sa_name   = "external-secrets"
}

data "aws_iam_policy_document" "eso_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eso" {
  name        = "${local.operators_cluster_name}-eso-policy"
  description = "IAM policy for External Secrets Operator to read Secrets Manager"
  policy      = data.aws_iam_policy_document.eso_policy.json
}

data "aws_iam_policy_document" "eso_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_host}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:${local.eso_namespace}:${local.eso_sa_name}"]
    }
  }
}

resource "aws_iam_role" "eso" {
  name               = "${local.operators_cluster_name}-eso-role"
  assume_role_policy = data.aws_iam_policy_document.eso_trust.json
}

resource "aws_iam_role_policy_attachment" "eso_attach" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}

resource "kubernetes_service_account" "eso_sa" {
  metadata {
    name      = local.eso_sa_name
    namespace = local.eso_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eso.arn
    }
    labels = {
      "app.kubernetes.io/name" = "external-secrets"
    }
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = local.eso_namespace
  version    = "0.9.13"

  # Wait for ALB controller webhook to be available to avoid admission failures
  depends_on = [
    kubernetes_service_account.eso_sa,
    aws_iam_role_policy_attachment.eso_attach,
    helm_release.aws_load_balancer_controller
  ]

  timeout = 600
  cleanup_on_fail = true

  values = [
    yamlencode({
      installCRDs   = true
      replicaCount  = 1
      serviceAccount = {
        create = false
        name   = local.eso_sa_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.eso.arn
        }
      }
    })
  ]
}

# --- Carts service IRSA for DynamoDB access ---
locals {
  carts_namespace = "retail-store"
  carts_sa_name   = "carts"
  carts_table_name = coalesce(try(data.terraform_remote_state.sandbox.outputs.dynamodb_table_name, null), "carts")
  carts_table_arn  = "arn:aws:dynamodb:${local.operators_region}:${data.aws_caller_identity.current.account_id}:table/${local.carts_table_name}"
}

resource "kubernetes_namespace" "retail_store" {
  metadata {
    name = local.carts_namespace
  }
}

data "aws_iam_policy_document" "carts_ddb_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem"
    ]
    resources = [
      local.carts_table_arn,
      "${local.carts_table_arn}/index/*"
    ]
  }
}

resource "aws_iam_policy" "carts_ddb" {
  name        = "${local.operators_cluster_name}-carts-ddb-policy"
  description = "IAM policy for carts service to access DynamoDB table"
  policy      = data.aws_iam_policy_document.carts_ddb_policy.json
}

data "aws_iam_policy_document" "carts_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_host}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:${local.carts_namespace}:${local.carts_sa_name}"]
    }
  }
}

resource "aws_iam_role" "carts" {
  name               = "${local.operators_cluster_name}-carts-role"
  assume_role_policy = data.aws_iam_policy_document.carts_trust.json
}

resource "aws_iam_role_policy_attachment" "carts_attach" {
  role       = aws_iam_role.carts.name
  policy_arn = aws_iam_policy.carts_ddb.arn
}

resource "kubernetes_service_account" "carts_sa" {
  metadata {
    name      = local.carts_sa_name
    namespace = local.carts_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.carts.arn
    }
    labels = {
      "app.kubernetes.io/name" = local.carts_sa_name
    }
  }
  depends_on = [kubernetes_namespace.retail_store, aws_iam_role_policy_attachment.carts_attach]
}

output "carts_irsa_role_arn" {
  description = "IAM Role ARN used by the carts service account via IRSA"
  value       = aws_iam_role.carts.arn
}
