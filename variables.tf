variable "team_map" {
  type = string
  description = "JSON file containing team to account mappings"
}

variable "s3_bucket_path" {
  type = string
  description = "S3 bucket where you would like to have the output file uploaded"
}