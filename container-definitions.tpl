[
  {
    "name": "${app_name}-${environment}-${task_name}",
    "image": "${repo_url}:${repo_tag}",
    "cpu": ${cpu},
    "memory": ${memory},
    "essential": true,
    "portMappings": [],
    "environment": [
      {"name": "OUTPUT", "value": "${output_path}"},
      {"name": "S3_BUCKET_PATH", "value": "${s3_results_bucket}"},
      {"name": "S3_KEY", "value": "${s3_key}"},
      {"name": "TEAM_MAP", "value": "${team_map}"}
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
