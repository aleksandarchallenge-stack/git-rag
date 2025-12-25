resource "google_artifact_registry_repository" "repo_rag" {
  description = "rag-repository-desc"
  format      = "DOCKER"

  labels = {
    managed-by-cnrm = "true"
  }

  location      = "europe-west4"
  mode          = "STANDARD_REPOSITORY"
  project       = "happtiq-demo-abanov-challenge"
  repository_id = "repo-rag"
}
# terraform import google_artifact_registry_repository.repo_rag projects/happtiq-demo-abanov-challenge/locations/europe-west4/repositories/repo-rag

resource "google_bigquery_dataset" "rag_dataset" {
  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "OWNER"
    user_by_email = "aleksandar.challenge@demo.happtiq.com"
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }

  access {
    role          = "WRITER"
    special_group = "projectWriters"
  }

  dataset_id                 = "rag_dataset"
  delete_contents_on_destroy = false

  labels = {
    managed-by-cnrm = "true"
  }

  location              = "EU"
  max_time_travel_hours = "168"
  project               = "happtiq-demo-abanov-challenge"
}
# terraform import google_bigquery_dataset.rag_dataset projects/happtiq-demo-abanov-challenge/datasets/rag_dataset

resource "google_bigquery_table" "release_notes_embeddings" {
  dataset_id = "rag_dataset"

  labels = {
    managed-by-cnrm = "true"
  }

  project  = "happtiq-demo-abanov-challenge"
  schema   = "[{\"name\":\"content\",\"type\":\"STRING\"},{\"mode\":\"REPEATED\",\"name\":\"embedding\",\"type\":\"FLOAT\"},{\"mode\":\"NULLABLE\",\"name\":\"doc_id\",\"type\":\"STRING\"},{\"mode\":\"NULLABLE\",\"name\":\"metadata\",\"type\":\"JSON\"},{\"name\":\"published_at\",\"type\":\"DATE\"}]"
  table_id = "release_notes_embeddings"
}
# terraform import google_bigquery_table.release_notes_embeddings projects/happtiq-demo-abanov-challenge/datasets/rag_dataset/tables/release_notes_embeddings

resource "google_service_account" "rag_app_sa" {
  account_id   = "rag-app-sa"
  display_name = "rag-app-sa"
  project      = "happtiq-demo-abanov-challenge"
}
# terraform import google_service_account.rag_app_sa projects/happtiq-demo-abanov-challenge/serviceAccounts/rag-app-sa@happtiq-demo-abanov-challenge.iam.gserviceaccount.com

resource "google_cloud_run_v2_service" "rag_app" {
  client  = "cloud-console"
  ingress = "INGRESS_TRAFFIC_ALL"

  labels = {
    managed-by-cnrm = "true"
  }

  launch_stage = "BETA"
  location     = "europe-west4"
  name         = "rag-app"
  project      = "happtiq-demo-abanov-challenge"

  template {
    containers {
      image = "europe-west4-docker.pkg.dev/happtiq-demo-abanov-challenge/repo-rag/rag-app:0f65cdcc749ba8f71bb0c86df71d56ff008a7581"
      name  = "rag-app-1"

      ports {
        container_port = 8080
        name           = "http1"
      }

      resources {
        cpu_idle = true

        limits = {
          cpu    = "1"
          memory = "512Mi"
        }

        startup_cpu_boost = true
      }

      startup_probe {
        failure_threshold     = 1
        initial_delay_seconds = 0
        period_seconds        = 240

        tcp_socket {
          port = 8080
        }

        timeout_seconds = 240
      }
    }

    max_instance_request_concurrency = 80

    scaling {
      max_instance_count = 2
    }

    service_account = "rag-app-sa@happtiq-demo-abanov-challenge.iam.gserviceaccount.com"
    timeout         = "300s"
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}
# terraform import google_cloud_run_v2_service.rag_app projects/happtiq-demo-abanov-challenge/locations/europe-west4/services/rag-app

resource "google_cloud_run_v2_job" "rag_indexer" {
  client       = "cloud-console"
  launch_stage = "GA"
  location     = "europe-west4"
  name         = "rag-indexer"
  project      = "happtiq-demo-abanov-challenge"

  template {
    task_count = 1

    template {
      containers {
        image = "europe-west4-docker.pkg.dev/happtiq-demo-abanov-challenge/repo-rag/rag-indexer@sha256:99b47de198332612dfd303e035751dd4cd60686c41311e821f8d5a40123f99b5"
        name  = "rag-indexer-1"

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }

      execution_environment = "EXECUTION_ENVIRONMENT_GEN2"
      max_retries           = 3
      service_account       = "1087330391168-compute@developer.gserviceaccount.com"
      timeout               = "600s"
    }
  }
}
# terraform import google_cloud_run_v2_job.rag_indexer projects/happtiq-demo-abanov-challenge/locations/europe-west4/jobs/rag-indexer
