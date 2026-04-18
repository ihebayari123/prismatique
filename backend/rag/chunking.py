from __future__ import annotations

from dataclasses import dataclass
import re


@dataclass(frozen=True)
class Chunk:
    text: str


def _normalize_paragraphs(text: str) -> list[str]:
    raw_parts = re.split(r"\n\s*\n+", text)
    parts: list[str] = []
    for part in raw_parts:
        clean = re.sub(r"\s+", " ", part).strip()
        if clean:
            parts.append(clean)
    return parts


def _sentence_split(text: str) -> list[str]:
    pieces = re.split(r"(?<=[.!?])\s+", text)
    return [piece.strip() for piece in pieces if piece and piece.strip()]


def chunk_text(
    text: str, *, chunk_size: int = 900, overlap: int = 120, min_chunk_size: int = 120
) -> list[Chunk]:
    paragraphs = _normalize_paragraphs(text)
    if not paragraphs:
        return []

    chunks: list[Chunk] = []

    current = ""
    for paragraph in paragraphs:
        candidate = paragraph if not current else f"{current}\n\n{paragraph}"
        if len(candidate) <= chunk_size:
            current = candidate
            continue

        if current.strip():
            chunks.append(Chunk(text=current.strip()))
            current = ""

        if len(paragraph) <= chunk_size:
            current = paragraph
            continue

        sentences = _sentence_split(paragraph)
        sentence_buffer = ""
        for sentence in sentences:
            sentence_candidate = (
                sentence if not sentence_buffer else f"{sentence_buffer} {sentence}"
            )
            if len(sentence_candidate) <= chunk_size:
                sentence_buffer = sentence_candidate
                continue

            if sentence_buffer.strip():
                chunks.append(Chunk(text=sentence_buffer.strip()))
                tail = sentence_buffer[-overlap:].strip()
                sentence_buffer = f"{tail} {sentence}".strip() if tail else sentence
            else:
                start = 0
                while start < len(sentence):
                    end = min(len(sentence), start + chunk_size)
                    window = sentence[start:end].strip()
                    if window:
                        chunks.append(Chunk(text=window))
                    if end == len(sentence):
                        break
                    start = max(0, end - overlap)
                sentence_buffer = ""

        if sentence_buffer.strip():
            current = sentence_buffer.strip()

    if current.strip():
        chunks.append(Chunk(text=current.strip()))

    merged: list[Chunk] = []
    for chunk in chunks:
        if merged and len(chunk.text) < min_chunk_size:
            merged[-1] = Chunk(text=f"{merged[-1].text}\n\n{chunk.text}".strip())
        else:
            merged.append(chunk)

    return merged
