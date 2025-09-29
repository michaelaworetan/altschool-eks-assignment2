# DuckDNS Dynamic DNS Update
resource "null_resource" "duckdns_update" {
  count = var.duckdns_token != null && var.duckdns_domain != null ? 1 : 0

  # Get EKS node public IP
  provisioner "local-exec" {
    command = <<-EOT
      NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
      curl "https://www.duckdns.org/update?domains=${var.duckdns_domain}&token=${var.duckdns_token}&ip=$NODE_IP"
    EOT
  }

  # Trigger update when node changes
  triggers = {
    node_instance_id = data.aws_instances.eks_nodes_duckdns[0].ids[0]
  }

  depends_on = [data.aws_instances.eks_nodes_duckdns]
}

# Get EKS node for DuckDNS
data "aws_instances" "eks_nodes_duckdns" {
  count = var.duckdns_token != null && var.duckdns_domain != null ? 1 : 0
  
  filter {
    name   = "tag:kubernetes.io/cluster/${local.operators_cluster_name}"
    values = ["owned"]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}