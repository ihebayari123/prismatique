from __future__ import annotations

import tempfile
from pathlib import Path

from fastapi import FastAPI, File, UploadFile
from fastapi import HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

try:
    from dotenv import load_dotenv

    load_dotenv()
except Exception:
    # .env loading is optional
    pass

from rag.config import get_settings
from rag.llm import (
    answer_with_ollama,
    answer_with_openai,
    answer_with_openrouter,
)
from rag.store import RagStore


settings = get_settings()
store = RagStore(
    data_dir=settings.data_dir,
    index_dir=settings.index_dir,
    embeddings_provider=settings.embeddings_provider,
    openai_api_key=settings.openai_api_key,
    openai_embedding_model=settings.openai_embedding_model,
    ollama_base_url=settings.ollama_base_url,
    ollama_embedding_model=settings.ollama_embedding_model,
)

app = FastAPI(title="Hackathon RAG Backend", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
static_dir = Path(__file__).resolve().parent / "static"
app.mount("/static", StaticFiles(directory=static_dir), name="static")


class QueryRequest(BaseModel):
    question: str = Field(min_length=1)
    top_k: int = Field(default=5, ge=1, le=20)
    use_llm: bool = True
    project: str | None = None


class ChatMessage(BaseModel):
    role: str = Field(pattern="^(user|assistant|system)$")
    content: str = Field(min_length=1)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1)
    history: list[ChatMessage] = Field(default_factory=list)
    top_k: int = Field(default=5, ge=1, le=20)
    project: str | None = None


class LibrarySearchRequest(BaseModel):
    query: str = Field(min_length=1)
    top_k: int = Field(default=8, ge=1, le=30)


def _build_sources(hits: list) -> list[dict]:
    return [
        {
            "project": h.meta.project,
            "filename": h.meta.filename,
            "page": h.meta.page,
            "chunk_index": h.meta.chunk_index,
            "score": round(h.score, 4),
            "snippet": h.meta.text[:600],
        }
        for h in hits
    ]


def _answer_with_fallback(
    *, question: str, snippets: list[str], history: list[dict[str, str]] | None = None
) -> tuple[str | None, str | None]:
    answer = ""
    llm_error: str | None = None

    if settings.openai_api_key:
        try:
            answer = answer_with_openai(
                question=question,
                snippets=snippets,
                model=settings.openai_model,
                history=history,
            )
        except Exception as e:
            llm_error = str(e)
    elif settings.openrouter_api_key:
        try:
            answer = answer_with_openrouter(
                question=question,
                snippets=snippets,
                base_url=settings.openrouter_base_url,
                api_key=settings.openrouter_api_key,
                model=settings.openrouter_model,
                history=history,
            )
        except Exception as e:
            llm_error = str(e)
    else:
        try:
            answer = answer_with_ollama(
                question=question,
                snippets=snippets,
                base_url=settings.ollama_base_url,
                model=settings.ollama_model,
                history=history,
            )
        except Exception as e:
            llm_error = str(e)
            answer = ""

    return answer or None, llm_error


@app.get("/health")
def health() -> dict:
    return {"ok": True}


@app.get("/")
def root() -> dict:
    return {
        "name": "Satacenter Gabes RAG Backend",
        "ok": True,
        "docs": "/docs",
        "health": "/health",
        "projects": "/projects",
        "query": "/query",
        "chat": "/chat",
        "ingest": "/ingest",
    }


@app.get("/playground")
def playground() -> FileResponse:
    return FileResponse(static_dir / "index.html")


@app.get("/projects")
def projects() -> dict:
    return {"projects": store.list_projects()}


@app.get("/projects/{project_name}")
def project_detail(project_name: str) -> dict:
    project = store.get_project(project_name)
    if project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return project


@app.post("/library/search")
def library_search(req: LibrarySearchRequest) -> dict:
    return {"results": store.library_search(query=req.query, top_k=req.top_k)}


@app.post("/ingest")
async def ingest(files: list[UploadFile] = File(...)) -> dict:
    results = []

    for f in files:
        suffix = Path(f.filename or "").suffix
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp_path = Path(tmp.name)
            tmp.write(await f.read())

        try:
            result = store.add_file(path=tmp_path, original_filename=f.filename)
            results.append({"filename": f.filename, **result})
        finally:
            try:
                tmp_path.unlink(missing_ok=True)
            except Exception:
                pass

    return {"ingested": results}


@app.post("/query")
def query(req: QueryRequest) -> dict:
    hits = store.search(query=req.question, top_k=req.top_k, project=req.project)
    sources = _build_sources(hits)

    if not req.use_llm:
        return {"answer": None, "sources": sources, "project": req.project}

    snippets = [h.meta.text for h in hits]
    answer, llm_error = _answer_with_fallback(question=req.question, snippets=snippets)

    return {
        "answer": answer,
        "sources": sources,
        "llm_error": llm_error,
        "project": req.project,
    }


@app.post("/chat")
def chat(req: ChatRequest) -> dict:
    hits = store.search(query=req.message, top_k=req.top_k, project=req.project)
    sources = _build_sources(hits)
    snippets = [h.meta.text for h in hits]
    history = [{"role": item.role, "content": item.content} for item in req.history]
    answer, llm_error = _answer_with_fallback(
        question=req.message,
        snippets=snippets,
        history=history,
    )

    return {
        "answer": answer,
        "sources": sources,
        "llm_error": llm_error,
        "project": req.project,
        "history_used": len(history),
    }
