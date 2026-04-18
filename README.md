# Satacenter Gabes RAG Backend

This project provides a clean FastAPI backend for a Flutter app that centralizes project documents from Gabes and lets decision-makers ask questions about them.

## What it does

- Upload PDF and DOCX documents with `POST /ingest`
- Build a project-oriented knowledge base from file contents
- Retrieve with hybrid search:
  - BM25 keyword search
  - Optional semantic embeddings with OpenAI or Ollama
- Ask one-shot questions with `POST /query`
- Run conversational RAG with `POST /chat`
- List indexed projects with `GET /projects`
- Return answer citations and source snippets for verification

The answer provider priority is:

- OpenAI if `OPENAI_API_KEY` is configured
- OpenRouter if `OPENROUTER_API_KEY` is configured
- Ollama otherwise

## Why this fits your hackathon use case

- It is easy to connect from Flutter because it uses simple REST endpoints.
- It is suitable for a "Gabes project decision center" because the API exposes projects, chat, and cited sources.
- It can run locally for demos with BM25 and Ollama.
- It stays usable even without paid APIs.

## Backend setup (Windows)

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r backend\requirements.txt

# Optional hosted setup
$env:OPENAI_API_KEY = "..."
$env:OPENAI_MODEL = "gpt-4o-mini"
$env:OPENAI_EMBEDDING_MODEL = "text-embedding-3-small"

# Optional OpenRouter setup
$env:OPENROUTER_API_KEY = "..."
$env:OPENROUTER_MODEL = "qwen/qwen3-next-80b-a3b-instruct"

# Optional fully local setup with Ollama
$env:EMBEDDINGS_PROVIDER = "ollama"
$env:OLLAMA_EMBEDDING_MODEL = "nomic-embed-text"
$env:OLLAMA_MODEL = "llama3.1:8b"

python -m uvicorn app:app --reload --port 8000
```

Open the docs at `http://127.0.0.1:8000/docs`.

## API

- `GET /health`
- `GET /projects`
- `POST /ingest`
- `POST /query`
- `POST /chat`

Example `POST /query` body:

```json
{
  "question": "What problem does this project solve?",
  "top_k": 5,
  "use_llm": true,
  "project": "ZARAT"
}
```

Example `POST /chat` body:

```json
{
  "message": "Can this project be executed quickly?",
  "project": "ZARAT",
  "top_k": 5,
  "history": [
    { "role": "user", "content": "Tell me about the project." },
    { "role": "assistant", "content": "..." }
  ]
}
```

Project filtering is optional. If you omit `project`, retrieval runs across all indexed documents.

## Flutter integration idea

Recommended flow:

1. Call `GET /projects` to display all available Gabes projects.
2. Let the user select a project or search all projects.
3. Send user messages to `POST /chat`.
4. Show the answer and the returned source snippets below it.

Returned sources include fields like:

```json
{
  "project": "ZARAT",
  "filename": "ZARAT.pdf",
  "page": 4,
  "chunk_index": 2,
  "score": 0.9182,
  "snippet": "..."
}
```

## Notes

- CORS is enabled so Flutter web/mobile testing is easier.
- If embeddings fail, BM25 retrieval still works.
- Existing index files can continue to load; missing metadata is backfilled automatically.
