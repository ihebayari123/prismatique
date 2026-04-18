from __future__ import annotations

from dataclasses import asdict, dataclass
import json
import re
from shutil import copy2
from pathlib import Path
from typing import Any
import uuid

import numpy as np
from rank_bm25 import BM25Okapi
import requests

from .chunking import chunk_text
from .parsers import parse_file


@dataclass(frozen=True)
class ChunkMeta:
    id: str
    project: str
    filename: str
    source_path: str
    page: int | None
    chunk_index: int
    text: str


@dataclass(frozen=True)
class SearchHit:
    score: float
    meta: ChunkMeta


class RagStore:
    def __init__(
        self,
        *,
        data_dir: Path,
        index_dir: Path,
        embeddings_provider: str,
        openai_api_key: str | None,
        openai_embedding_model: str,
        ollama_base_url: str,
        ollama_embedding_model: str,
    ):
        self.data_dir = data_dir
        self.index_dir = index_dir
        self.embeddings_provider = embeddings_provider
        self.openai_api_key = openai_api_key
        self.openai_embedding_model = openai_embedding_model
        self.ollama_base_url = ollama_base_url
        self.ollama_embedding_model = ollama_embedding_model

        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.index_dir.mkdir(parents=True, exist_ok=True)

        self._meta: list[ChunkMeta] = []
        self._embeddings: np.ndarray | None = None

        self._bm25: BM25Okapi | None = None
        self._bm25_corpus: list[list[str]] | None = None

        self._meta_path = self.index_dir / "meta.jsonl"
        self._embeddings_path = self.index_dir / "embeddings.npy"
        self._embeddings_info_path = self.index_dir / "embeddings_info.json"

        self._load_if_exists()

    @staticmethod
    def _project_name(filename: str) -> str:
        stem = Path(filename).stem
        cleaned = re.sub(r"[_\-]+", " ", stem)
        cleaned = re.sub(r"\s+", " ", cleaned).strip()
        return cleaned or filename

    def _current_embeddings_info(self) -> dict[str, str | None]:
        provider = self._resolve_embeddings_provider()
        model: str | None
        if provider == "openai":
            model = self.openai_embedding_model
        elif provider == "ollama":
            model = self.ollama_embedding_model
        else:
            model = None
        return {"provider": provider, "model": model}

    def _resolve_embeddings_provider(self) -> str:
        p = (self.embeddings_provider or "auto").strip().lower()
        if p in {"bm25", "none", "off", "disabled"}:
            return "none"
        if p == "openai":
            return "openai" if self.openai_api_key else "none"
        if p == "ollama":
            return "ollama" if self.ollama_embedding_model else "none"

        # auto
        if self.openai_api_key:
            return "openai"
        if self.ollama_embedding_model:
            return "ollama"
        return "none"

    def _load_if_exists(self) -> None:
        if self._meta_path.exists():
            self._meta = []
            for line in self._meta_path.read_text(encoding="utf-8").splitlines():
                if not line.strip():
                    continue
                obj = json.loads(line)
                obj.setdefault("project", self._project_name(obj["filename"]))
                obj.setdefault("chunk_index", 0)
                self._meta.append(ChunkMeta(**obj))

        # Load embeddings only if they match the current provider+model
        expected = self._current_embeddings_info()
        actual = None
        if self._embeddings_info_path.exists():
            try:
                actual = json.loads(self._embeddings_info_path.read_text(encoding="utf-8"))
            except Exception:
                actual = None

        if actual == expected and self._embeddings_path.exists():
            self._embeddings = np.load(self._embeddings_path).astype("float32")
        else:
            self._embeddings = None

    def _persist(self) -> None:
        # meta
        with self._meta_path.open("w", encoding="utf-8") as f:
            for m in self._meta:
                f.write(json.dumps(asdict(m), ensure_ascii=False) + "\n")
        # embeddings
        if self._embeddings is not None:
            np.save(self._embeddings_path, self._embeddings)
            self._embeddings_info_path.write_text(
                json.dumps(self._current_embeddings_info(), ensure_ascii=False),
                encoding="utf-8",
            )

    @staticmethod
    def _normalize_scores(scores: np.ndarray) -> np.ndarray:
        if scores.size == 0:
            return scores
        min_score = float(scores.min())
        max_score = float(scores.max())
        if max_score - min_score < 1e-9:
            if max_score <= 0:
                return np.zeros_like(scores, dtype="float32")
            return np.ones_like(scores, dtype="float32")
        return ((scores - min_score) / (max_score - min_score)).astype("float32")

    def list_projects(self) -> list[dict[str, Any]]:
        projects: dict[str, dict[str, Any]] = {}
        for meta in self._meta:
            bucket = projects.setdefault(
                meta.project,
                {
                    "project": meta.project,
                    "documents": set(),
                    "chunks": 0,
                    "pages": set(),
                },
            )
            bucket["documents"].add(meta.filename)
            bucket["chunks"] += 1
            if meta.page is not None:
                bucket["pages"].add(meta.page)

        items = []
        for project, data in projects.items():
            items.append(
                {
                    "project": project,
                    "document_count": len(data["documents"]),
                    "chunk_count": data["chunks"],
                    "page_count": len(data["pages"]) or None,
                }
            )
        return sorted(items, key=lambda item: item["project"].lower())

    def get_project(self, project: str) -> dict[str, Any] | None:
        normalized = project.strip().lower()
        matches = [meta for meta in self._meta if meta.project.lower() == normalized]
        if not matches:
            return None

        documents = sorted({meta.filename for meta in matches})
        pages = sorted({meta.page for meta in matches if meta.page is not None})
        preview_chunks: list[str] = []
        seen_texts: set[str] = set()
        for meta in matches:
            text = meta.text.strip()
            if not text or text in seen_texts:
                continue
            seen_texts.add(text)
            preview_chunks.append(text)
            if len(preview_chunks) >= 3:
                break

        summary = " ".join(preview_chunks)[:900].strip()
        return {
            "project": matches[0].project,
            "document_count": len(documents),
            "chunk_count": len(matches),
            "page_count": len(pages) or None,
            "documents": documents,
            "summary": summary,
            "sample_sources": [
                {
                    "filename": meta.filename,
                    "page": meta.page,
                    "chunk_index": meta.chunk_index,
                    "snippet": meta.text[:320],
                }
                for meta in matches[:5]
            ],
        }

    def library_search(self, *, query: str, top_k: int = 10) -> list[dict[str, Any]]:
        hits = self.search(query=query, top_k=max(top_k * 3, top_k))
        project_scores: dict[str, float] = {}
        project_snippets: dict[str, str] = {}
        project_files: dict[str, set[str]] = {}

        for hit in hits:
            project = hit.meta.project
            project_scores[project] = max(project_scores.get(project, 0.0), hit.score)
            project_files.setdefault(project, set()).add(hit.meta.filename)
            project_snippets.setdefault(project, hit.meta.text[:320])

        ranked = sorted(
            project_scores.items(),
            key=lambda item: (-item[1], item[0].lower()),
        )[:top_k]
        return [
            {
                "project": project,
                "score": round(score, 4),
                "document_count": len(project_files.get(project, set())),
                "snippet": project_snippets.get(project, ""),
            }
            for project, score in ranked
        ]

    @staticmethod
    def _tokenize(text: str) -> list[str]:
        return re.findall(r"[a-zA-Z0-9]+", text.lower())

    def _ensure_bm25(self) -> None:
        if self._bm25 is not None and self._bm25_corpus is not None:
            return
        corpus = [self._tokenize(m.text) for m in self._meta]
        self._bm25_corpus = corpus
        self._bm25 = BM25Okapi(corpus) if corpus else None

    def _embed_openai(self, texts: list[str]) -> np.ndarray:
        if not self.openai_api_key:
            raise RuntimeError("OpenAI embeddings requested but OPENAI_API_KEY is not set")

        # Imported lazily so BM25-only mode works even if OpenAI isn't installed.
        from openai import OpenAI  # type: ignore

        client = OpenAI(api_key=self.openai_api_key)

        vectors: list[list[float]] = []
        batch_size = 64
        for start in range(0, len(texts), batch_size):
            batch = texts[start : start + batch_size]
            out = client.embeddings.create(model=self.openai_embedding_model, input=batch)
            # OpenAI returns data possibly out-of-order; sort by index to be safe
            data_sorted = sorted(out.data, key=lambda d: d.index)
            vectors.extend([d.embedding for d in data_sorted])

        arr = np.asarray(vectors, dtype="float32")
        # Normalize so dot-product == cosine similarity
        norms = np.linalg.norm(arr, axis=1, keepdims=True)
        norms[norms == 0] = 1.0
        return arr / norms

    def _embed_ollama(self, texts: list[str]) -> np.ndarray:
        if not self.ollama_embedding_model:
            raise RuntimeError("Ollama embeddings requested but OLLAMA_EMBEDDING_MODEL is not set")

        base_url = self.ollama_base_url.rstrip("/")

        # Prefer batch endpoint if available.
        try:
            resp = requests.post(
                f"{base_url}/api/embed",
                json={"model": self.ollama_embedding_model, "input": texts},
                timeout=120,
            )
            if resp.status_code == 404:
                raise requests.HTTPError("/api/embed not found", response=resp)
            resp.raise_for_status()
            data = resp.json()
            vectors = data.get("embeddings")
            if vectors is None and "embedding" in data and len(texts) == 1:
                vectors = [data["embedding"]]
            if not vectors:
                raise RuntimeError("Ollama embed endpoint returned no embeddings")
        except requests.HTTPError as e:
            if getattr(e, "response", None) is None or e.response.status_code != 404:
                raise

            # Fallback to older single-input endpoint.
            vectors = []
            for t in texts:
                r = requests.post(
                    f"{base_url}/api/embeddings",
                    json={"model": self.ollama_embedding_model, "prompt": t},
                    timeout=120,
                )
                r.raise_for_status()
                d = r.json()
                emb = d.get("embedding")
                if not emb:
                    raise RuntimeError("Ollama embeddings endpoint returned no embedding")
                vectors.append(emb)

        arr = np.asarray(vectors, dtype="float32")
        norms = np.linalg.norm(arr, axis=1, keepdims=True)
        norms[norms == 0] = 1.0
        return arr / norms

    def _embed(self, texts: list[str]) -> np.ndarray:
        provider = self._resolve_embeddings_provider()
        if provider == "openai":
            return self._embed_openai(texts)
        if provider == "ollama":
            return self._embed_ollama(texts)
        raise RuntimeError("Embeddings provider is disabled")

    def add_file(self, *, path: Path, original_filename: str | None = None) -> dict[str, Any]:
        # Copy into data_dir with unique name to avoid collisions
        file_id = str(uuid.uuid4())
        safe_name = original_filename or path.name
        stored_path = self.data_dir / f"{file_id}_{safe_name}"
        copy2(path, stored_path)

        pages = parse_file(stored_path)
        new_chunks: list[ChunkMeta] = []
        project = self._project_name(safe_name)
        for page in pages:
            for chunk_index, chunk in enumerate(chunk_text(page.text), start=1):
                new_chunks.append(
                    ChunkMeta(
                        id=str(uuid.uuid4()),
                        project=project,
                        filename=safe_name,
                        source_path=str(stored_path),
                        page=page.page,
                        chunk_index=chunk_index,
                        text=chunk.text,
                    )
                )

        if not new_chunks:
            return {"file_id": file_id, "project": project, "chunks_added": 0}

        self._meta.extend(new_chunks)

        # Embeddings are optional (semantic search). BM25 always works as fallback.
        provider = self._resolve_embeddings_provider()
        if provider != "none":
            try:
                vectors = self._embed([c.text for c in new_chunks])
                if self._embeddings is None:
                    self._embeddings = vectors
                else:
                    self._embeddings = np.vstack([self._embeddings, vectors]).astype("float32")
            except Exception:
                # If embedding fails (e.g., Ollama not running), keep BM25 fallback working.
                self._embeddings = None

        # Invalidate BM25 cache
        self._bm25 = None
        self._bm25_corpus = None

        self._persist()

        return {"file_id": file_id, "project": project, "chunks_added": len(new_chunks)}

    def search(self, *, query: str, top_k: int = 5, project: str | None = None) -> list[SearchHit]:
        if not self._meta:
            return []

        eligible = np.arange(len(self._meta))
        if project:
            normalized_project = project.strip().lower()
            eligible = np.asarray(
                [
                    idx
                    for idx, meta in enumerate(self._meta)
                    if meta.project.lower() == normalized_project
                    or meta.filename.lower() == normalized_project
                ],
                dtype=int,
            )
        if eligible.size == 0:
            return []

        self._ensure_bm25()
        hybrid_scores = np.zeros(len(self._meta), dtype="float32")

        if self._bm25 is not None:
            q_tokens = self._tokenize(query)
            bm25_scores = np.asarray(self._bm25.get_scores(q_tokens), dtype="float32")
            hybrid_scores += 0.45 * self._normalize_scores(bm25_scores)

        if self._embeddings is not None and self._resolve_embeddings_provider() != "none":
            try:
                qv = self._embed([query])[0]
                semantic_scores = (self._embeddings @ qv).astype("float32")
                hybrid_scores += 0.55 * self._normalize_scores(semantic_scores)
            except Exception:
                pass

        filtered_scores = hybrid_scores[eligible]
        k = min(top_k, filtered_scores.shape[0])
        if k <= 0:
            return []

        idxs = np.argpartition(-filtered_scores, kth=k - 1)[:k]
        idxs = idxs[np.argsort(-filtered_scores[idxs])]
        selected = eligible[idxs]

        hits = [
            SearchHit(score=float(hybrid_scores[i]), meta=self._meta[int(i)]) for i in selected
        ]
        deduped: list[SearchHit] = []
        seen: set[tuple[str, int | None, int]] = set()
        for hit in hits:
            key = (hit.meta.filename, hit.meta.page, hit.meta.chunk_index)
            if key in seen:
                continue
            seen.add(key)
            deduped.append(hit)
        return deduped
