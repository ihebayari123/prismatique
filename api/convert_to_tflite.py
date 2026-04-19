from __future__ import annotations

from pathlib import Path
import sys

import tensorflow as tf

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from api.inference import _load_model, default_model_paths


def convert(h5_path: Path, out_path: Path, float16: bool = True) -> None:
    model = _load_model(h5_path)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # Useful defaults for mobile
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    if float16:
        converter.target_spec.supported_types = [tf.float16]

    tflite_model = converter.convert()
    out_path.write_bytes(tflite_model)


if __name__ == "__main__":
    paths = default_model_paths()
    convert(paths.classifier_h5, paths.classifier_h5.with_suffix(".tflite"))
    convert(paths.unet_h5, paths.unet_h5.with_suffix(".tflite"))
    print("Done")
