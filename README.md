# Q&A RAG app on GCP
## Architecture
<img width="1241" height="972" alt="Untitled Diagram drawio (1)" src="https://github.com/user-attachments/assets/b3ec30b2-87b2-495e-bc95-9d01aa8b6127" />

## Steps I took while building
Embeddings will be stored on BQ, however, I need to decide on how to generate them.

Embeddings Generation Design decision: BQML vs. LangChain python SDK:

Using BQML I can directly generate the embeddings using SQL and the data will never leave BQ.
No need to manage python env and deal with API quotas and error rates. Even huge volumes would be easily handled by BQ.
Autonomous embedding generation could also be used where inserting new data in the table would automatically generate embeddings.

Using LangChain SDK, I had to deal with the API errors and choose an appropriate batch size for a request.
Setting it up in a python env gives me more flexibility if any additional data processing is needed.
Also swapping embeddings models here is quite easy because of LangChain.

I went with the LangChain SDK for embedding generation.

1. Created rag_dataset and release_notes_embeddings to hold the embeddings.
2. Created indexer.py.
    Some issues using code suggested by LLMs:
       -Outdated imports & depreciated classes.
       -Suggested sequential API calls using embed_query instead of batch with embed_documents.
       -Suggested to use the Streaming API instead of a Load Job of the batched embeddings.
       -Ran into 400 error because of exceeding the token limit of Vertex AI, lower batch_size.
   
Chuncking decision: since the content of the rows is not too lengtly it fits the max seq. length of the model of 2048 tokens so we treat each row's content as a documnet and don't consider splitting into chuncks.

BQ ingestion decision: batch load is more appropriate than a streaming load, we don't need sub-second latency and we don't pay for batch inserts.

BQ ingestion decision: WRITE_APPEND to the vectore store directly. Major pro is simplicity. As an alternative we clould use WRITE_TRUNCATE and WRITE_APPEND that load the batches to a staging table and then have a MERGE into the vector store. This makes the load idempotent, it is safe to retry if there's an error and the MERGE controlls for duplicates. Also it works well if I was to introduce a retry logic. And it has no downtime since the prod table is updated in one transaction at the end.

BQ ingestion decision: Because I hit the embeddings model token limit if I have more than 30 rows per API request I have interleaved the embed_documents calls together with a batch load on BQ. For every 30 rows I do a load job. It might me much better to accumulate all 2000 rows and load them once at the end all together. Otherwise, I wait for initialization of the job every batch and use up the 1500 loads jobs per day for the table. The main restriction is the python memory but it should be able to handle much more than thousands of rows.

4. Create rag_app.py.

Promt decision: Since we have a single turn requiremnt we can use the simple PromptTemplate for a single turn QnA instead of ChatPromptTemplate.

Vector store decision: We are using a BQ table, we can use BigQueryVectorStore directly for simplicity, if we want low-latency for actual production we should consider VertexFSVectorStore or even Google Cloud Vertex AI Vector Search which demands infrastructure set up.

Vector index decision: Didn't create a vector index for the vector store since our table is <10 MB and GCP woudn't use it anyway.

LLM model decision: Used gemini-2.5-flash for cheap and fast performance, really easy to swap.
5. Create app.py to serve as the frontend. Quite simple frontend no decision challenges.

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

Design decision: 

---

Level 3

16. Cloud Run/Services/Security/IAP edit policy and add the principles to have access.
17. Add a published_at column to use as a watermark in the release_notes_embeddings table
    We only load new data after max(published_at). Since published_at is a date this assumes source data is loaded fully for each day.
18. incr_load.py very similar to the indexer.py but uses the watermark to load only new records.
19. Create a job on Cloud Run. Use cloud scheduler to make it run every morning.
