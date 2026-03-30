output "dbt_runner_secret_id" {
  description = "Secret Manager secret ID for dbt runner credentials"
  value       = google_secret_manager_secret.dbt_runner_key.secret_id
}
output "cloudbuild_sa_id" {
  description = "Cloud Build service account ID"
  value       = google_service_account.cloudbuild_sa.id
}