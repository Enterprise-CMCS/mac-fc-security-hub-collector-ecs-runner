[
  {
    "name": "${app_name}-${environment}-${task_name}",
    "image": "${repo_url}:${repo_tag}",
    "cpu": ${cpu},
    "memory": ${memory},
    "essential": true,
    "portMappings": [],
    "environment": [
      {"name": "S3_BUCKET", "value": "${s3_results_bucket}"},
      {"name": "S3_KEY", "value": "${s3_key}"},
      {"name": "BASE64_TEAM_MAP", "value": "${base64_team_map}"},
      {"name": "TEAMS_API_BASE_URL", "value": "${teams_api_base_url}"},
      {"name": "COLLECTOR_ROLE_PATH", "value": "${collector_role_path}"}
    ],
    "secrets": [
      {"name": "TEAMS_API_KEY", "valueFrom": "${teams_api_key_param}"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "secretOptions": null,
      "options": {
        "awslogs-group": "${awslogs_group}",
        "awslogs-region": "${awslogs_region}",
        "awslogs-stream-prefix": "${app_name}"
      }
    },
    "mountPoints": [],
    "volumesFrom": [],
    "entryPoint": [
            "/bin/security-hub-collector"
    ]
  }
]
