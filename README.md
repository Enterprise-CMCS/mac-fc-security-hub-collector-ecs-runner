# security-hub-collector-ecs-runner

This repo contains a Terraform module which will deploy a scheduled ECS
task which can run a periodic InSpec scan against an AWS account. The module supports following features:

* Run an ECS task which collects results from Security Hub and outputs to a CSV file in a specified S3 bucket
* Cloudwatch rule to run tasks on a cron based cadence

## Usage

```hcl
module "security_hub_collector_runner" {
  source      = "github.com/CMSgov/security-hub-collector-ecs-runner?ref=8b712aa2da6b4d900e0d0d60aa732fae048a1b69"
  app_name    = "security-hub"
  environment = "dev"

  task_name      = "scheduled-collector"
  repo_arn       = module.cms_ars_repo.arn
  repo_url       = module.cms_ars_repo.repo_url
  repo_tag       = "latest"
  ecs_vpc_id     = data.aws_vpc.mac_fc_example_east_sandbox.id
  ecs_subnet_ids = [data.aws_subnet.private_a.id]

  schedule_task_expression  = "cron(30 9 * * ? *)"
  logs_cloudwatch_group_arn = aws_cloudwatch_log_group.main.arn
  ecs_cluster_arn           = "arn:aws:ecs:us-east-1:037370603820:cluster/aws-scanner-inspec"

  output_path       = ""
  s3_results_bucket = aws_s3_bucket.security_hub_collector.bucket
  s3_key            = ""
  team_map          = filebase64("${path.module}/teammap.json")
  assume_role       = "security-hub-collector"
}
```
## Required Parameters
| Name | Description |
|------|---------|
| s3_results_bucket | Bucket value to store security hub collector results. If value is a valid bucket path, CSV files will be streamed to it. |
| team_map | JSON file containing team to account mappings. |

## Optional Parameters

| Name | Default Value | Description |
|------|---------|---------|
| assume_role | "" | Role name to assume when collecting across all accounts |
| logs_cloudwatch_group_arn | "" | CloudWatch log group arn, overrides values of logs_cloudwatch_retention & logs_cloudwatch_group |
| output_path | "SecurityHub-Findings.csv" | File to direct output to.|
| s3_results_bucket | "" | Bucket value to store security hub collector results. If value is a valid bucket path, CSV files will be streamed to it. |
| s3_key | "--output" | The S3 key (path/filename) to use (defaults to --output, will have timestamp inserted in name) |


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
