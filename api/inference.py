from __future__ import annotations

import base64
import io
import os
import threading
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Tuple

import numpy as np
from PIL import Image

# Keras/TensorFlow imports stay inside load functions to make
# module import fast and to keep error messages focused.


@dataclass(frozen=True)
class ModelPaths:
    classifier_h5: Path
    unet_h5: Path


_classifier_model = None
_unet_model = None
_classifier_lock = threading.Lock()
_unet_lock = threading.Lock()


def _workspace_root() -> Path:
    # api/ is expected to live under the workspace root.
    return Path(__file__).resolve().parent.parent


def default_model_paths() -> ModelPaths:
    root = _workspace_root()
    models_dir = root / "models"
    return ModelPaths(
        classifier_h5=_pick_model_path(
            os.getenv("DATE_PALM_CLASSIFIER_MODEL"),
            [
                models_dir / "date_palm_disease_model.h5",
                root / "date_palm_disease_model.h5",
            ],
        ),
        unet_h5=_pick_model_path(
            os.getenv("DATE_PALM_UNET_MODEL"),
            [
                models_dir / "unet_date_palm_segmentation.h5",
                root / "unet_date_palm_segmentation.h5",
            ],
        ),
    )


def _pick_model_path(env_value: str | None, candidates: list[Path]) -> Path:
    if env_value:
        return Path(env_value).expanduser().resolve()

    for candidate in candidates:
        if candidate.exists():
            return candidate

    return candidates[0]


def _standalone_keras_v3():
    try:
        import keras
    except ImportError:
        return None

    version = str(getattr(keras, "__version__", "0"))
    major = version.split(".", 1)[0]
    if major.isdigit() and int(major) >= 3:
        return keras
    return None


def _load_model(model_path: Path):
    standalone_keras = _standalone_keras_v3()
    if standalone_keras is not None:
        return standalone_keras.models.load_model(model_path, compile=False)

    import tensorflow as tf

    try:
        return tf.keras.models.load_model(model_path, compile=False)
    except Exception as e:  # noqa: BLE001
        raise RuntimeError(
            "Failed to load the .h5 model with TensorFlow's bundled Keras loader. "
            "These model files were likely saved with newer Keras serialization. "
            'Install standalone Keras 3 in this virtual environment with '
            '`pip install "keras>=3,<4" --no-deps` and retry.'
        ) from e


def load_classifier_model(paths: ModelPaths | None = None):
    global _classifier_model
    if _classifier_model is not None:
        return _classifier_model

    paths = paths or default_model_paths()
    if not paths.classifier_h5.exists():
        raise FileNotFoundError(f"Classifier model not found: {paths.classifier_h5}")

    with _classifier_lock:
        if _classifier_model is not None:
            return _classifier_model

        _classifier_model = _load_model(paths.classifier_h5)
        return _classifier_model


def load_unet_model(paths: ModelPaths | None = None):
    global _unet_model
    if _unet_model is not None:
        return _unet_model

    paths = paths or default_model_paths()
    if not paths.unet_h5.exists():
        raise FileNotFoundError(f"U-Net model not found: {paths.unet_h5}")

    with _unet_lock:
        if _unet_model is not None:
            return _unet_model

        _unet_model = _load_model(paths.unet_h5)
        return _unet_model


def _model_hwcn(input_shape: Tuple[int, ...]) -> Tuple[int, int, int]:
    """Returns (H, W, C) for common Keras input shapes.

    Accepts shapes like:
    - (None, H, W, C)
    - (H, W, C)
    """
    if len(input_shape) == 4:
        # (batch, H, W, C)
        h, w, c = input_shape[1], input_shape[2], input_shape[3]
    elif len(input_shape) == 3:
        h, w, c = input_shape
    else:
        raise ValueError(f"Unsupported input shape: {input_shape}")

    if any(v is None for v in (h, w, c)):
        raise ValueError(
            f"Model has dynamic spatial dims; please hardcode resize: {input_shape}"
        )

    return int(h), int(w), int(c)


def prepare_image(image: Image.Image, input_shape: Tuple[int, ...]) -> np.ndarray:
    h, w, c = _model_hwcn(input_shape)
    image = image.convert("RGB")
    image = image.resize((w, h))

    arr = np.asarray(image).astype(np.float32)

    # Basic normalization: [0..255] -> [0..1].
    # If your model was trained with mean/std normalization, update this.
    arr = arr / 255.0

    if c == 1:
        # Convert RGB to grayscale if needed.
        arr = np.mean(arr, axis=-1, keepdims=True)

    # Add batch dimension.
    return np.expand_dims(arr, axis=0)


def decode_image_bytes(data: bytes) -> Image.Image:
    return Image.open(io.BytesIO(data))


def encode_png_base64(image: Image.Image) -> str:
    buf = io.BytesIO()
    image.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")


def predict_disease(image_bytes: bytes) -> Dict[str, Any]:
    model = load_classifier_model()
    input_shape = tuple(getattr(model, "input_shape"))

    img = decode_image_bytes(image_bytes)
    x = prepare_image(img, input_shape)

    y = model.predict(x, verbose=0)
    y = np.asarray(y)

    # Typical classifier outputs:
    # - shape (1, 1): sigmoid
    # - shape (1, N): softmax/logits
    y1 = np.ravel(y[0]).astype(float)
    if y1.size == 1:
        predicted_index = int(y1[0] >= 0.5)
        predicted_score = float(y1[0])
    else:
        predicted_index = int(np.argmax(y1))
        predicted_score = float(y1[predicted_index])

    return {
        "input_shape": list(input_shape),
        "raw_output": y1.tolist(),
        "predicted_index": predicted_index,
        "predicted_score": predicted_score,
    }


def segment_date_palm(image_bytes: bytes, threshold: float = 0.5) -> Dict[str, Any]:
    model = load_unet_model()
    input_shape = tuple(getattr(model, "input_shape"))

    img = decode_image_bytes(image_bytes)
    x = prepare_image(img, input_shape)

    y = model.predict(x, verbose=0)
    y = np.asarray(y)

    # Expect something like (1, H, W, 1) or (1, H, W, C)
    mask = y[0]
    if mask.ndim == 3 and mask.shape[-1] > 1:
        # Multi-class: take argmax for visualization.
        mask_vis = np.argmax(mask, axis=-1).astype(np.uint8)
        # Scale to 0..255 for display.
        if mask_vis.max() > 0:
            mask_vis = (mask_vis * (255 // int(mask_vis.max()))).astype(np.uint8)
    else:
        # Binary: threshold and scale to 0/255
        if mask.ndim == 3:
            mask = mask[..., 0]
        mask_vis = (mask >= threshold).astype(np.uint8) * 255

    mask_img = Image.fromarray(mask_vis, mode="L")
    mask_b64 = encode_png_base64(mask_img)

    return {
        "input_shape": list(input_shape),
        "mask_png_base64": mask_b64,
    }


def model_info() -> Dict[str, Any]:
    info: Dict[str, Any] = {}
    try:
        clf = load_classifier_model()
        info["classifier"] = {
            "input_shape": list(getattr(clf, "input_shape")),
            "output_shape": list(getattr(clf, "output_shape")),
        }
    except Exception as e:  # noqa: BLE001
        info["classifier_error"] = str(e)

    try:
        unet = load_unet_model()
        info["unet"] = {
            "input_shape": list(getattr(unet, "input_shape")),
            "output_shape": list(getattr(unet, "output_shape")),
        }
    except Exception as e:  # noqa: BLE001
        info["unet_error"] = str(e)

    return info
