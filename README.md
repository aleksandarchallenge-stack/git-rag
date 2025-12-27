# Q&A RAG app on GCP
## Architecture
<img width="1241" height="972" alt="Untitled Diagram drawio (1)" src="https://github.com/user-attachments/assets/b3ec30b2-87b2-495e-bc95-9d01aa8b6127" />

## Steps I took while building

1. Created rag_dataset and release_notes_embeddings to hold the embeddings.
2. Created indexer.py.
    Some issues using code suggested by LLMs:
       -Outdated imports & depreciated classes.
       -Suggested sequential API calls using embed_query instead of batch with embed_documents.
       -Suggested to use the Streaming API instead of a Load Job of the batched embeddings.
       -Ran into 400 error because of exceeding the token limit of Vertex AI, lower batch_size.
3. Create rag_app.py.
    -Use simple PromptTemplate for a single turn QnA.
    -Didn't create a vector index for the vector store since our table is <10 MB and GCP woudn't use it anyway.
    -Used gemini-2.5-flash for cheap and fast performance. 
4. Create app.py to serve as the frontend. 

---

Level 1

5. Create a Service Account.
6. Create a repo in Artifact registry.
7. Build the docker image to the repo.
    -Here got org policy violation because of 'us' region, had to create a bucket in the eu manually with [PROJECT_ID]_cloudbuild
8. Deploy to cloud Run. with min-instances=0.
9. Set up a git repo
10. Add cloudbuild.yaml file
11. Create a cloud Build trigger

---

Level 2

12. Bulk export all project resources to terraform.
13. Keep only the core resources Artifact, BQ, Cloud Run, SA
14. Create a iam.tr for the IAM roles of the SA
15. Create import blocks for the core resources Artifact, BQ, Cloud Run, SA

---

Level 3

16. Cloud Run/Services/Security/IAP edit policy and add the principles to have access.
17. Add a published_at column to use as a watermark in the release_notes_embeddings table
    We only load new data after max(published_at). Since published_at is a date this assumes source data is loaded fully for each day.
18. incr_load.py very similar to the indexer.py but uses the watermark to load only new records.
19. Create a job on Cloud Run. Use cloud scheduler to make it run every morning.
