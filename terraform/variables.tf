variable "aws_region" {
  description = "AWS region for the Kubernetes cluster"
  type        = string
  default     = "eu-north-1"
}

variable "cluster_name" {
  description = "Name of the EKS Kubernetes cluster"
  type        = string
  default     = "capstone-voting-cluster"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "node_instance_type" {
  description = "EC2 instance type for Kubernetes worker nodes"
  type        = string
  default     = "t3.small"
}
