# 1. Service Account
import {
  to = google_service_account.rag_app_sa
  id = "projects/happtiq-demo-abanov-challenge/serviceAccounts/rag-app-sa@happtiq-demo-abanov-challenge.iam.gserviceaccount.com"
}

# 2. Artifact Registry
import {
  to = google_artifact_registry_repository.repo_rag
  id = "projects/happtiq-demo-abanov-challenge/locations/europe-west4/repositories/repo-rag"
}

# 3. BigQuery Dataset
import {
  to = google_bigquery_dataset.rag_dataset
  id = "projects/happtiq-demo-abanov-challenge/datasets/rag_dataset"
}

# 4. BigQuery Table
import {
  to = google_bigquery_table.release_notes_embeddings
  id = "projects/happtiq-demo-abanov-challenge/datasets/rag_dataset/tables/release_notes_embeddings"
}

# 5. Cloud Run Service
import {
  to = google_cloud_run_v2_service.rag_app
  id = "projects/happtiq-demo-abanov-challenge/locations/europe-west4/services/rag-app"
}

# 6. Cloud Run Job
import {
  to = google_cloud_run_v2_job.rag_indexer
  id = "projects/happtiq-demo-abanov-challenge/locations/europe-west4/jobs/rag-indexer"
}