output "task_execution_role_arn" {
  description = "ARN for the IAM role that is executing the scanner"
  value       = aws_iam_role.task_execution_role.arn
}

output "ecs_cluster_arn" {
  description = "ARN for the ECS cluster where this profile will execute"
  value       = var.ecs_cluster_arn
}

output "task_security_group_id" {
  description = "Security group of the ECS task"
  value       = aws_security_group.ecs_sg.id
}

output "task_definition_arn_without_revision" {
  description = "ARN of the ECS task definition without revision"
  value       = aws_ecs_task_definition.scheduled_task_def.arn_without_revision
}
