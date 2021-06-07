output "task_execution_role_arn" {
  description = "ARN for the IAM role that is executing the scanner"
  value       = aws_iam_role.task_role.arn
}

output "ecs_cluster_arn" {
  description = "ARN for the ECS cluster where this profile will execute"
  value       = var.ecs_cluster_arn == "" ? aws_ecs_cluster.inspec_cluster[0].arn : var.ecs_cluster_arn
}