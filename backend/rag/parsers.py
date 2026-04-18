from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from pypdf import PdfReader
from docx import Document


@dataclass(frozen=True)
class ParsedPage:
    text: str
    page: int | None


def parse_pdf(path: Path) -> list[ParsedPage]:
    reader = PdfReader(str(path))
    pages: list[ParsedPage] = []
    for idx, page in enumerate(reader.pages, start=1):
        text = page.extract_text() or ""
        pages.append(ParsedPage(text=text, page=idx))
    return pages


def parse_docx(path: Path) -> list[ParsedPage]:
    doc = Document(str(path))
    parts = [p.text for p in doc.paragraphs if p.text and p.text.strip()]
    text = "\n".join(parts)
    return [ParsedPage(text=text, page=None)]


def parse_file(path: Path) -> list[ParsedPage]:
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        return parse_pdf(path)
    if suffix in {".docx", ".doc"}:
        # Note: legacy .doc isn't reliably supported; user should convert to .docx.
        return parse_docx(path)
    raise ValueError(f"Unsupported file type: {suffix}")
