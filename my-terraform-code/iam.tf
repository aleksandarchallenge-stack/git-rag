
variable "rag_roles" {
  type = list(string)
  default = [
    "roles/artifactregistry.writer",
    "roles/bigquery.dataEditor",
    "roles/bigquery.dataViewer",
    "roles/bigquery.jobUser",
    "roles/run.admin",
    "roles/run.invoker",
    "roles/logging.logWriter",
    "roles/iam.serviceAccountUser",
    "roles/aiplatform.user"
  ]
}

resource "google_project_iam_member" "rag_app_permissions" {
  for_each = toset(var.rag_roles)
  
  project = "happtiq-demo-abanov-challenge"
  role    = each.key
  member  = "serviceAccount:${google_service_account.rag_app_sa.email}"
}