locals {
  awslogs_group    = split(":", var.logs_cloudwatch_group_arn)[6]
  decoded_team_map = var.team_config.base64_team_map != null ? jsondecode(base64decode(var.team_config.base64_team_map)) : null
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cloudwatch_logs_allow_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }

    actions = [
      "kms:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow logs KMS access"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
  }
}

# Create a data source to pull the latest active revision from
data "aws_ecs_task_definition" "scheduled_task_def" {
  task_definition = aws_ecs_task_definition.scheduled_task_def.family
  depends_on      = [aws_ecs_task_definition.scheduled_task_def] # ensures at least one task def exists
}

# Assume Role policies

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "events_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    effect = "Allow"
  }
}

# SG - ECS

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-${var.app_name}-${var.environment}"
  description = "${var.app_name}-${var.environment} container security group"
  vpc_id      = var.ecs_vpc_id

  tags = {
    Name        = "ecs-${var.app_name}-${var.environment}"
    Environment = var.environment
    Automation  = "Terraform"
  }
}

resource "aws_security_group_rule" "app_ecs_allow_outbound" {
  description       = "Allow all outbound"
  security_group_id = aws_security_group.ecs_sg.id

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

## ECS schedule task

# Allows CloudWatch Rule to run ECS Task

data "aws_iam_policy_document" "cloudwatch_target_role_policy_doc" {
  statement {
    actions   = ["iam:PassRole"]
    resources = ["*"]
  }

  statement {
    actions   = ["ecs:RunTask"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "cloudwatch_target_role" {
  name                 = "cw-target-role-${var.app_name}-${var.environment}-${var.task_name}"
  description          = "Role allowing CloudWatch Events to run the task"
  assume_role_policy   = data.aws_iam_policy_document.events_assume_role_policy.json
  path                 = var.role_path
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy" "cloudwatch_target_role_policy" {
  name   = "${aws_iam_role.cloudwatch_target_role.name}-policy"
  role   = aws_iam_role.cloudwatch_target_role.name
  policy = data.aws_iam_policy_document.cloudwatch_target_role_policy_doc.json
}

# Task role
resource "aws_iam_role" "task_role" {
  name                 = "ecs-task-role-${var.app_name}-${var.environment}-${var.task_name}"
  description          = "Role allowing container definition to execute"
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume_role_policy.json
  path                 = var.role_path
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy_attachment" "read_only_everything" {
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  role       = aws_iam_role.task_role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    # If a team map is provided, add a resource entry for each role ARN in the map.
    # Otherwise, if a Teams API configuration is provided, add a single entry for a role ARN constructed from the provided role path
    resources = local.decoded_team_map != null ? (
      flatten([for group in local.decoded_team_map.teams : [for account in group.accounts : account.roleArn]])
    ) : [(var.team_config.teams_api != null && var.team_config.teams_api.collector_role_path != null) ? "arn:aws:iam::*:role/${var.team_config.teams_api.collector_role_path}" : ""]
  }
}

resource "aws_iam_policy" "assume_role" {
  name   = "assume-role-${var.app_name}-${var.environment}-${var.task_name}"
  path   = var.role_path
  policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "assume_role" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.assume_role.arn
}

resource "aws_iam_policy" "s3" {
  name   = "assume-role-${var.app_name}-${var.environment}-${var.task_name}"
  path   = var.role_path
  policy = data.aws_iam_policy_document.s3.json
}

data "aws_iam_policy_document" "s3" {
  statement {
    sid    = "CollectorResultsS3Access"
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.s3_results_bucket}",
      "arn:aws:s3:::${var.s3_results_bucket}/*"
    ]
    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.s3.arn
}

# Task execution role
resource "aws_iam_role" "task_execution_role" {
  name                 = "ecs-task-exec-role-${var.app_name}-${var.environment}-${var.task_name}"
  description          = "Role allowing ECS tasks to execute"
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume_role_policy.json
  path                 = var.role_path
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy" "task_execution_role_policy" {
  name   = "${aws_iam_role.task_execution_role.name}-policy"
  role   = aws_iam_role.task_execution_role.name
  policy = data.aws_iam_policy_document.task_execution_role_policy_doc.json
}

data "aws_iam_policy_document" "task_execution_role_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${var.logs_cloudwatch_group_arn}:*"]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = [var.repo_arn]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:/${var.app_name}-${var.environment}*",
    ]
  }

  statement {
    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.app_name}-${var.environment}*",
    ]
  }
}

#
# CloudWatch
#

resource "aws_cloudwatch_event_rule" "run_command" {
  name                = "${var.task_name}-${var.environment}"
  description         = "Scheduled task for ${var.task_name} in ${var.environment}"
  schedule_expression = var.schedule_task_expression
  state               = var.scheduled_task_state
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  target_id = "run-scheduled-task-${var.task_name}-${var.environment}"
  arn       = var.ecs_cluster_arn
  rule      = aws_cloudwatch_event_rule.run_command.name
  role_arn  = aws_iam_role.cloudwatch_target_role.arn

  ecs_target {
    launch_type = "FARGATE"
    task_count  = 1

    # Use latest active revision
    task_definition_arn = aws_ecs_task_definition.scheduled_task_def.arn

    network_configuration {
      subnets          = var.ecs_subnet_ids
      security_groups  = [aws_security_group.ecs_sg.id]
      assign_public_ip = var.assign_public_ip
    }
  }
}

# ECS task details

resource "aws_ecs_task_definition" "scheduled_task_def" {
  family        = "${var.app_name}-${var.environment}-${var.task_name}"
  network_mode  = "awsvpc"
  task_role_arn = aws_iam_role.task_role.arn

  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = aws_iam_role.task_execution_role.arn

  container_definitions = templatefile("${path.module}/container-definitions.tpl",
    {
      app_name            = var.app_name,
      environment         = var.environment,
      task_name           = var.task_name,
      repo_url            = var.repo_url,
      repo_tag            = var.repo_tag,
      s3_results_bucket   = var.s3_results_bucket,
      s3_key              = var.s3_key,
      base64_team_map     = var.team_config.base64_team_map != null ? var.team_config.base64_team_map : "",
      teams_api_base_url  = var.team_config.teams_api != null ? var.team_config.teams_api.base_url : "",
      teams_api_key_param = var.team_config.teams_api != null ? var.team_config.teams_api.api_key_param : "",
      collector_role_path = var.team_config.teams_api != null ? var.team_config.teams_api.collector_role_path : "",
      awslogs_group       = local.awslogs_group,
      awslogs_region      = data.aws_region.current.name,
      cpu                 = var.ecs_cpu,
      memory              = var.ecs_memory
    }
  )
}
