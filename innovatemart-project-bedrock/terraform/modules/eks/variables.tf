variable "cluster_name" {
  description = "Unique identifier for the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region where the cluster resources will be provisioned"
  type        = string
}

variable "cluster_version" {
  description = "Version of Kubernetes to run on the EKS control plane"
  type        = string
  default     = "1.33"
}

variable "vpc_id" {
  description = "ID of the VPC that will host the cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where cluster nodes and resources will be placed"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type used for worker nodes in the node group"
  type        = string
  default     = "t4g.small"
}

variable "desired_capacity" {
  description = "Target number of nodes to maintain in the worker node group"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of nodes allowed in the node group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Upper limit of nodes that can be scaled to in the node group"
  type        = number
  default     = 2
}

variable "node_group_name" {
  description = "Optional custom name for the worker node group"
  type        = string
  default     = null
}
variable "tags" {
  description = "Custom tags to attach to all EKS-related resources"
  type        = map(string)
  default     = {}
}