from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings
from langchain_google_community import BigQueryVectorStore
from langchain_core.prompts import PromptTemplate
from langchain_core.runnables import RunnableParallel, RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser

embeddings = GoogleGenerativeAIEmbeddings(
    model="text-embedding-005",
    project="happtiq-demo-abanov-challenge",
    vertexai=True)

vectorstore = BigQueryVectorStore(
    project_id="happtiq-demo-abanov-challenge",
    dataset_name="rag_dataset",
    table_name="release_notes_embeddings",
    location="EU",
    embedding=embeddings,
    content_field="content", 
    text_embedding_field="embedding"
)

def concatenate_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

retriever = vectorstore.as_retriever(
    search_kwargs={"k": 3}
) | concatenate_docs

template = """You are a helpful Google Cloud Support Expert.
Use the provided release notes snippets to answer the user's question. 
If the answer isn't in the notes, say you don't know—don't make up dates.

Context (Release Notes):
{notes}

User Question: {query}

Answer:"""

prompt = PromptTemplate.from_template(template)

llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    temperature=0.2,
    max_output_tokens=500,
    project="happtiq-demo-abanov-challenge",
    vertexai=True
)

rag_chain = (
    RunnableParallel({
        "notes": retriever,
        "query": RunnablePassthrough()
    })
    | prompt
    | llm
    | StrOutputParser()
)

def answer(question: str) -> str:
    return rag_chain.invoke(question)