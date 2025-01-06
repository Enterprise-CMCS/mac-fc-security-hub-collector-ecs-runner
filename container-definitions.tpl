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
      {"name": "ATHENA_TEAMS_TABLE", "value": "${athena_teams_table}"},
      {"name": "QUERY_OUTPUT_LOCATION", "value": "${query_output_location}"},
      {"name": "COLLECTOR_ROLE_PATH", "value": "${collector_role_path}"}
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
