# Kubernetes Ingress for UI service with SSL/TLS
resource "kubernetes_ingress_v1" "ui_ingress" {
  count = var.manage_ui_ingress ? 1 : 0

  metadata {
    name      = "ui-ingress"
    namespace = "retail-store"
    annotations = {
      "kubernetes.io/ingress.class"                    = "alb"
      "alb.ingress.kubernetes.io/scheme"               = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"          = "ip"
      "alb.ingress.kubernetes.io/listen-ports"         = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"         = "443"
      "alb.ingress.kubernetes.io/certificate-arn"      = var.ingress_hostname != null ? aws_acm_certificate.ui_cert[0].arn : ""
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/"
      "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/tags"                 = "Environment=sandbox,Project=innovatemart"
    }
  }

  spec {
    rule {
      host = var.ingress_hostname
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "ui-svc"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # Default backend for requests without host header
    default_backend {
      service {
        name = "ui-svc"
        port {
          number = 80
        }
      }
    }
  }

  depends_on = [
    helm_release.aws_load_balancer_controller,
    aws_acm_certificate_validation.ui_cert
  ]
}