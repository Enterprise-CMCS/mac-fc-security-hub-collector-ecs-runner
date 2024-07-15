# security-hub-collector-ecs-runner

This repo contains a Terraform module for a scheduled ECS task that periodically collects Security Hub findings from the specified AWS accounts. To read more about the security-hub-collector CLI tool, go to [this repository](https://github.com/CMSgov/security-hub-collector). The module supports the following features:

* Run an ECS task that collects results from Security Hub and outputs them to a CSV file in a specified S3 bucket
* Cloudwatch rule to run tasks on a cron-based cadence

## Usage

```hcl
module "security_hub_collector_runner" {
  source      = "github.com/CMSgov/security-hub-collector-ecs-runner"
  app_name    = "security-hub"
  environment = "dev"

  task_name            = "scheduled-collector"
  repo_arn             = module.cms_ars_repo.arn
  repo_url             = module.cms_ars_repo.repo_url
  repo_tag             = "latest"
  ecs_vpc_id           = data.aws_vpc.mac_fc_example_east_sandbox.id
  ecs_subnet_ids       = [data.aws_subnet.private_a.id]
  ecs_cpu              = // optional, defaults to 256
  ecs_memory           = // optional, defaults to 1024
  assign_public_ip     = // optional, defaults to false
  role_path            = // optional, defaults to "/"
  permissions_boundary = // optional, defaults to ""

  schedule_task_expression  = "cron(30 9 * * ? *)"
  scheduled_task_enabled    = // optional, defaults to ENABLED
  logs_cloudwatch_group_arn = aws_cloudwatch_log_group.main.arn
  ecs_cluster_arn           = "arn:aws:ecs:us-east-1:037370603820:cluster/aws-scanner-inspec"

  output_path       = ""
  s3_results_bucket = aws_s3_bucket.security_hub_collector.bucket
  s3_key            = ""
  team_map          = filebase64("${path.module}/teammap.json") // read more in Required Parameters
}
```

## Required Parameters

| Name | Description |
|------|---------|
| s3_results_bucket | Bucket value to store security hub collector results. If value is a valid bucket path, CSV files will be streamed to it. |
| team_map | JSON file containing team to account mappings. The JSON is base64 encoded so that it can be passed as a string to the task definition and is decoded in the container for use with the security hub collector tool. Base64 encoding is required to avoid error when attempting to run this module. |

## Optional Parameters

| Name | Default Value | Description |
|------|---------|---------|
| logs_cloudwatch_group_arn | "" | CloudWatch log group arn, overrides values of logs_cloudwatch_retention & logs_cloudwatch_group |
| output_path | "SecurityHub-Findings.csv" | File to direct output to.|
| s3_results_bucket | "" | Bucket value to store security hub collector results. If value is a valid bucket path, CSV files will be streamed to it. |
| s3_key | "--output" | The S3 key (path/filename) to use (defaults to --output, will have timestamp inserted in name) |
| ecs_cpu | 256 | The hard limit of CPU units (in CPU units) allocated to the ECS task |
| ecs_memory | 1024 | The hard limit of memory (in MiB) allocated to the ECS task |
| scheduled_task_enabled | ENABLED | Whether the scheduled ECS task is enabled or not |


## Outputs

| Name | Description |
|------|---------|
| task_execution_role_arn | ARN for the IAM role that is executing the scanner |
| ecs_cluster_arn | ARN for the ECS cluster where this profile will execute |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Modules

No Modules.
