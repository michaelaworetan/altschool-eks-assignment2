# Route53 A record pointing to EKS node for NodePort access
resource "aws_route53_record" "nodeport_domain" {
  count   = var.route53_zone_id != null && var.ingress_hostname != null && !var.manage_ui_ingress ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.ingress_hostname
  type    = "A"
  ttl     = 300
  records = [data.aws_instance.eks_node[0].public_ip]
}

# Get EKS node public IP
data "aws_instances" "eks_nodes" {
  count = var.route53_zone_id != null && var.ingress_hostname != null && !var.manage_ui_ingress ? 1 : 0
  
  filter {
    name   = "tag:kubernetes.io/cluster/${local.operators_cluster_name}"
    values = ["owned"]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "eks_node" {
  count       = var.route53_zone_id != null && var.ingress_hostname != null && !var.manage_ui_ingress ? 1 : 0
  instance_id = data.aws_instances.eks_nodes[0].ids[0]
}