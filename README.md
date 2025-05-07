# security-hub-collector-ecs-runner

This repo contains a Terraform module for a scheduled ECS task that periodically collects Security Hub findings from the specified AWS accounts. To read more about the security-hub-collector CLI tool, go to [this repository](https://github.com/CMSgov/security-hub-collector). The module supports the following features:

* Run an ECS task that collects results from Security Hub and outputs them to a CSV file in a specified S3 bucket
* Cloudwatch rule to run tasks on a cron-based cadence
* Supports two methods of configuration: direct team mapping or Teams API-based team lookup

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

  schedule_task_expression  = "cron(30 9 * * ? *)"
  logs_cloudwatch_group_arn = aws_cloudwatch_log_group.main.arn
  ecs_cluster_arn           = "arn:aws:ecs:us-east-1:037370603820:cluster/aws-scanner-inspec"

  output_path       = ""
  s3_results_bucket = aws_s3_bucket.security_hub_collector.bucket
  s3_key            = ""

  # Exactly one of base64_team_map and teams_api must be provided
  team_config = {
    base64_team_map : base64encode(file("${path.module}/teammap.json"))

    teams_api : {
      base_url            : "https://vshjmodi2c-vpce-0eea951a9e855a573.execute-api.us-east-1.amazonaws.com/teams-api-prod"
      api_key_param       : "my-api-key-param"
      collector_role_path : "my/role/path"
    }
  }
}
```

## Required Parameters

| Name | Description |
|------|------------|
| app_name | Name of the application |
| environment | Environment name |
| task_name | Name of the task to be run |
| repo_arn | ARN of the ECR repo hosting the scanner container image |
| repo_url | The url of the ECR repo to pull images and run in ecs |
| ecs_vpc_id | VPC ID to be used by ECS |
| s3_results_bucket | Bucket value to store security hub collector results |
| logs_cloudwatch_group_arn | CloudWatch log group arn for container logs |
| ecs_cluster_arn | ECS cluster ARN to use for running this profile |
| ecs_subnet_ids | Subnet IDs for the ECS tasks |
| team_config | Configuration for team-to-account mapping |

`team_config` must contain exactly one of these keys:
- `base64_team_map`: String containing team mapping configuration
- `teams_api`: Object containing Teams API configuration settings

## Configuration Options

### Team Map Configuration
When using `base64_team_map`, provide a base64 encoded JSON string containing team to account mappings. The JSON is decoded in the container for use with the security hub collector tool.

### Teams API Configuration
When using `teams_api`, provide an object with the following required fields:
- `base_url`: Base URL of the Teams API
- `api_key_param`: Name of SSM parameter containing the Teams API key
- `collector_role_path`: Path of the IAM role that allows the Collector to access Security Hub

## Optional Parameters

| Name | Default Value | Description |
|------|--------------|-------------|
| repo_tag | "latest" | The tag to identify and pull the image in ECR repo |
| output_path | "" | File to direct output to |
| s3_key | "" | The S3 key (path/filename) to use |
| assign_public_ip | false | Choose whether to assign a public IP address |
| role_path | "/" | The path for IAM roles and policies |
| permissions_boundary | "" | ARN of the permissions boundary policy |
| ecs_cpu | 256 | CPU units allocated to the ECS task |
| ecs_memory | 1024 | Memory (MiB) allocated to the ECS task |
| schedule_task_expression | "cron(30 9 * * ? *)" | Cron schedule for the task |
| scheduled_task_state | "ENABLED" | State of the scheduled task |

## Outputs

| Name | Description |
|------|------------|
| task_execution_role_arn | ARN for the IAM role executing the scanner |
| task_security_group_id | ID of the task security group, for allowing traffic from the scanner |
| ecs_cluster_arn | ARN for the ECS cluster |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Modules

No Modules.
