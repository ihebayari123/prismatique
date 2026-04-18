from __future__ import annotations

import os
from typing import Iterable

import requests


def _format_context(snippets: Iterable[tuple[int, str]]) -> str:
    parts = []
    for i, text in snippets:
        parts.append(f"[S{i}] {text}")
    return "\n\n".join(parts)


def _format_history(history: list[dict[str, str]] | None) -> str:
    if not history:
        return ""

    lines = []
    for message in history[-8:]:
        role = (message.get("role") or "user").strip().lower()
        content = (message.get("content") or "").strip()
        if not content:
            continue
        label = "User" if role == "user" else "Assistant"
        lines.append(f"{label}: {content}")
    return "\n".join(lines)


def _system_prompt() -> str:
    return (
        "You are Satacenter Gabes, a decision-support assistant for projects in Gabes. "
        "Answer using ONLY the provided snippets. "
        "If the answer is not supported by the snippets, clearly say you do not know. "
        "Be precise, practical, and concise. "
        "When relevant, summarize project objectives, stakeholders, risks, actions, or execution details. "
        "Cite supporting snippets like [S1], [S2]."
    )


def answer_with_ollama(
    *,
    question: str,
    snippets: list[str],
    base_url: str,
    model: str,
    history: list[dict[str, str]] | None = None,
) -> str:
    context = _format_context(list(enumerate(snippets, start=1)))
    history_text = _format_history(history)
    prompt = (
        f"{_system_prompt()}\n\n"
        f"CHAT HISTORY:\n{history_text or 'None'}\n\n"
        f"SNIPPETS:\n{context}\n\nQUESTION: {question}\nANSWER:"
    )

    resp = requests.post(
        f"{base_url.rstrip('/')}/api/generate",
        json={"model": model, "prompt": prompt, "stream": False},
        timeout=120,
    )
    if resp.status_code >= 400:
        # Make setup issues obvious (e.g. model not pulled yet).
        raise RuntimeError(
            f"Ollama error {resp.status_code} for model '{model}': {resp.text.strip()}"
        )
    data = resp.json()
    return (data.get("response") or "").strip()


def answer_with_openai(
    *,
    question: str,
    snippets: list[str],
    model: str,
    history: list[dict[str, str]] | None = None,
) -> str:
    # Imported lazily so retrieval-only mode works without OpenAI installed.
    from openai import OpenAI  # type: ignore

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY is not set")

    client = OpenAI(api_key=api_key)

    context = _format_context(list(enumerate(snippets, start=1)))
    user = (
        f"CHAT HISTORY:\n{_format_history(history) or 'None'}\n\n"
        f"SNIPPETS:\n{context}\n\nQUESTION: {question}"
    )

    out = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": _system_prompt()},
            {"role": "user", "content": user},
        ],
        temperature=0.2,
    )
    return (out.choices[0].message.content or "").strip()


def answer_with_openrouter(
    *,
    question: str,
    snippets: list[str],
    base_url: str,
    api_key: str,
    model: str,
    history: list[dict[str, str]] | None = None,
) -> str:
    """Answer using OpenRouter's OpenAI-compatible Chat Completions API.

    Note: In OpenRouter's HTTP API, model names are typically like
    "qwen/qwen3-next-80b-a3b-instruct" (no "openrouter/" prefix).
    """

    context = _format_context(list(enumerate(snippets, start=1)))
    user = (
        f"CHAT HISTORY:\n{_format_history(history) or 'None'}\n\n"
        f"SNIPPETS:\n{context}\n\nQUESTION: {question}"
    )

    normalized_model = model.strip()
    if normalized_model.startswith("openrouter/"):
        normalized_model = normalized_model[len("openrouter/") :]

    url = f"{base_url.rstrip('/')}/chat/completions"
    resp = requests.post(
        url,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json={
            "model": normalized_model,
            "messages": [
                {"role": "system", "content": _system_prompt()},
                {"role": "user", "content": user},
            ],
            "temperature": 0.2,
        },
        timeout=120,
    )
    if resp.status_code >= 400:
        raise RuntimeError(
            f"OpenRouter error {resp.status_code} for model '{normalized_model}': {resp.text.strip()}"
        )
    data = resp.json()
    try:
        return (data["choices"][0]["message"]["content"] or "").strip()
    except Exception:
        raise RuntimeError(f"Unexpected OpenRouter response: {data}")
