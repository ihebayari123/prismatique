from __future__ import annotations

"""ASGI entrypoint for running the backend from the repo root.

This shim lets you run:

  python -m uvicorn app:app --reload --port 8000

from the repository root, while keeping the actual FastAPI implementation in
`backend/app.py`.
"""

import importlib.util
import sys
from pathlib import Path

_BACKEND_DIR = Path(__file__).resolve().parent / "backend"

# Make `backend/rag` importable as top-level `rag` for the existing backend code.
if str(_BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(_BACKEND_DIR))

_spec = importlib.util.spec_from_file_location("backend_app", _BACKEND_DIR / "app.py")
if _spec is None or _spec.loader is None:
    raise RuntimeError("Failed to load backend/app.py")

_backend_app = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = _backend_app
_spec.loader.exec_module(_backend_app)

app = _backend_app.app
