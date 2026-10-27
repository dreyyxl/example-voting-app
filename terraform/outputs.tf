output "cluster_name" {
  description = "Name of the EKS Kubernetes cluster"
  value       = aws_eks_cluster.voting.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = aws_eks_cluster.voting.endpoint
}

output "cluster_region" {
  description = "AWS region where the cluster is deployed"
  value       = var.aws_region
}

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.voting.id
}

output "node_group_name" {
  description = "Name of the EKS worker node group"
  value       = aws_eks_node_group.voting.node_group_name
}
