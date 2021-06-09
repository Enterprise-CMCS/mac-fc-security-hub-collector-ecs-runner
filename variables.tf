variable "app_name" {
  type        = string
  description = "Name of the application"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "task_name" {
  type        = string
  description = "Name of the task to be run"
}

variable "repo_arn" {
  type = string
  description = "ARN of the ECR repo hosting the scanner container image"
}

variable "repo_url" {
  type        = string
  description = "The url of the ECR repo to pull images and run in ecs"
}

variable "repo_tag" {
  type        = string
  description = "The tag to identify and pull the image in ECR repo"
  default     = "latest"
}

variable "ecs_vpc_id" {
  type = string
  description = "VPC ID to be used by ECS"
}

variable "output_path" {
  type = string
  description = "File to direct output to. (default: SecurityHub-Findings.csv)"
  default = ""
}

variable "s3_results_bucket" {
  type        = string
  description = "S3 bucket where you would like to have the output file uploaded"
}

variable "s3_key" {
  type = string
  description = "The S3 key (path/filename) to use (defaults to --output, will have timestamp inserted in name)"
  default = ""
}

variable "team_map" {
  type        = string
  description = "JSON file containing team to account mappings"
}

variable "schedule_task_expression" {
  type = string
  description = "Cron based schedule task to run on a cadence"
  default = "cron(30 9 * * ? *)" // run 9:30 everyday"
}

variable "logs_cloudwatch_group_arn" {
  description = "CloudWatch log group arn for container logs"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ECS cluster ARN to use for running this profile"
  type        = string
}

variable "ecs_subnet_ids" {
  description = "Subnet IDs for the ECS tasks."
  type        = list(string)
}