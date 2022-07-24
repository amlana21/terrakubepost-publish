output "cluster_vpc_id" {
  description = "vpc id"
  value       = module.vpc.vpc_id
}

output "cluster_private_subnets" {
  description = "private subnet ids"
  value       = module.vpc.private_subnets
}