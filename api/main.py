from __future__ import annotations

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from .inference import model_info, predict_disease, segment_date_palm

app = FastAPI(title="Date Palm Models API")

# For local development with Flutter, enabling wide-open CORS is simplest.
# Tighten this for production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"ok": True}


@app.get("/info")
def info():
    return model_info()


@app.post("/predict-disease")
async def predict_disease_route(file: UploadFile = File(...)):
    if file.content_type is None or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Upload an image file")

    image_bytes = await file.read()
    try:
        return predict_disease(image_bytes)
    except Exception as e:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/segment")
async def segment_route(file: UploadFile = File(...), threshold: float = 0.5):
    if file.content_type is None or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Upload an image file")

    image_bytes = await file.read()
    try:
        return segment_date_palm(image_bytes, threshold=threshold)
    except Exception as e:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(e))
