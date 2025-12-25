# --- Provider Configuration ---
provider "google" {
  project = "happtiq-demo-abanov-challenge"
  region  = "europe-west4"
}

# --- 1. Artifact Registry Repository ---
resource "google_artifact_registry_repository" "repo_rag" {
  location      = "europe-west4"
  repository_id = "repo-rag"
  description   = "Docker repository for RAG app"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }
}

# --- 2. Dedicated Service Account ---
resource "google_service_account" "rag_app_sa" {
  account_id   = "rag-app-sa"
  display_name = "Service Account for RAG Application"
}

# --- 3. IAM Permissions for the App ---
locals {
  app_roles = [
    "roles/artifactregistry.writer",
    "roles/bigquery.dataEditor",
    "roles/bigquery.dataViewer",
    "roles/bigquery.jobUser",
    "roles/run.admin",
    "roles/logging.logWriter",
    "roles/iam.serviceAccountUser",
    "roles/aiplatform.user"
  ]
}

resource "google_project_iam_member" "app_permissions" {
  for_each = toset(local.app_roles)
  project  = "happtiq-demo-abanov-challenge"
  role     = each.key
  member   = "serviceAccount:${google_service_account.rag_app_sa.email}"
}

# --- 4. Cloud Run Service ---
resource "google_cloud_run_v2_service" "rag_app" {
  name     = "rag-app"
  location = "europe-west4"
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      max_instance_count = 2
      min_instance_count = 0
    }

    containers {
      image = "europe-west4-docker.pkg.dev/happtiq-demo-abanov-challenge/repo-rag/rag-app:v1"
      
      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        startup_cpu_boost = true
      }
    }

    service_account = google_service_account.rag_app_sa.email
  }

  # This allows public access (Unauthenticated)
  lifecycle {
    ignore_changes = [
      client,
      client_version,
    ]
  }
}

# Make the service public
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.rag_app.location
  name     = google_cloud_run_v2_service.rag_app.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}