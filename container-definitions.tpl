[
  {
    "name": "${app_name}-${environment}-${task_name}",
    "image": "${repo_url}:${repo_tag}",
    "cpu": 128,
    "memory": 1024,
    "essential": true,
    "portMappings": [],
    "environment": [
      {"name": "TEAM_MAP", "value": "${team_map}"},
      {"name": "S3_BUCKET_PATH", "value": "${s3_results_bucket}"}
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
            "./scriptRunner.sh"
    ]
  }
]