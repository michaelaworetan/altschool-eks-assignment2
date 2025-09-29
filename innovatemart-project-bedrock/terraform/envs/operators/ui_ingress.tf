locals {
  ui_namespace = "retail-store"
  ui_service   = "ui-svc"
  # Use the cluster subnets for ALB placement (public subnets in sandbox)
  lb_subnets   = data.aws_eks_cluster.this.vpc_config[0].subnet_ids
}

resource "kubernetes_ingress_v1" "ui" {
  count = var.manage_ui_ingress ? 1 : 0

  metadata {
    name      = "ui-alb-ingress"
    namespace = local.ui_namespace
    annotations = merge(
      {
        "kubernetes.io/ingress.class"           = "alb"
        "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
        "alb.ingress.kubernetes.io/target-type" = "ip"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/actuator/health/liveness"
        # Be explicit about which subnets to use for the ALB to avoid discovery issues
        "alb.ingress.kubernetes.io/subnets"     = join(",", local.lb_subnets)
      },
      // If we have a cert, enable HTTPS and set cert ARN; otherwise only HTTP 80
      (try(module.acm[0].acm_certificate_arn, null) != null)
        ? {
            "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]",
            "alb.ingress.kubernetes.io/certificate-arn" = module.acm[0].acm_certificate_arn
          }
        : {
            "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}]"
          },
      // If hostname is provided, let ExternalDNS manage it
      var.ingress_hostname != null ? {"external-dns.alpha.kubernetes.io/hostname" = var.ingress_hostname} : {}
    )
  }

  spec {
    # Prefer spec.ingressClassName over the legacy annotation
    ingress_class_name = "alb"
    // Rule with hostname
    dynamic "rule" {
      for_each = var.ingress_hostname != null ? [var.ingress_hostname] : []
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = local.ui_service
                port {
                  number = 80
                }
              }
            }
          }
        }
      }
    }
    // Rule without hostname (catch-all)
    dynamic "rule" {
      for_each = var.ingress_hostname == null ? [1] : []
      content {
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = local.ui_service
                port {
                  number = 80
                }
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.aws_load_balancer_controller,
    helm_release.externaldns
  ]
}