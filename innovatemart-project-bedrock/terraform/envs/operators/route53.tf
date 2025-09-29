# Route53 A record pointing to ALB
resource "aws_route53_record" "ui_domain" {
  count   = var.route53_zone_id != null && var.ingress_hostname != null ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.ingress_hostname
  type    = "A"

  alias {
    name                   = kubernetes_ingress_v1.ui_ingress[0].status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb.ui_alb[0].zone_id
    evaluate_target_health = true
  }

  depends_on = [kubernetes_ingress_v1.ui_ingress]
}

# Data source to get ALB details
data "aws_lb" "ui_alb" {
  count = var.route53_zone_id != null && var.ingress_hostname != null ? 1 : 0
  name  = split("-", kubernetes_ingress_v1.ui_ingress[0].status[0].load_balancer[0].ingress[0].hostname)[0]

  depends_on = [kubernetes_ingress_v1.ui_ingress]
}