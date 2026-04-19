# Palm Tree Model API For Prismatique

This branch packages the palm tree computer vision backend as a FastAPI service so a Flutter app can call it from another PC, an Android emulator, an iPhone simulator, or a real device on the same network.

## What is included

- A FastAPI API with two endpoints:
  - `POST /predict-disease`
  - `POST /segment`
- Keras model loading with Windows-friendly compatibility logic
- PowerShell helper scripts to set up, run, and test the API
- A Flutter request example in `api/flutter_example.dart.txt`

## Repository structure

```text
api/
  main.py
  inference.py
  requirements.txt
  convert_to_tflite.py
  flutter_example.dart.txt
models/
  README.md
scripts/
  setup_api.ps1
  run_api.ps1
  test_api.ps1
```

## Important note about the model files

The API expects these files:

- `models/date_palm_disease_model.h5`
- `models/unet_date_palm_segmentation.h5`

If they are not present after cloning, copy them into the `models/` folder manually from your current PC, external storage, cloud storage, or another trusted source.

Why they may not be in Git by default:

- `date_palm_disease_model.h5` is about 134 MB
- GitHub blocks normal Git files larger than 100 MB
- If you want to version these files in GitHub, use Git LFS

## Clone on another PC

```powershell
git lfs install
git clone --branch Palm_Tree_Model --single-branch https://github.com/ihebayari123/prismatique.git
cd prismatique
```

If the models are stored in Git LFS later, also run:

```powershell
git lfs pull
```

If the models are not in the repository yet, copy them into `models/` with the exact names listed above.

## Python requirement

Use Python 3.11 on Windows.

This project should not be installed with Python 3.13 or 3.14 for the API because TensorFlow support is version-sensitive there.

## Easy setup on another PC

From the repository root:

```powershell
.\scripts\setup_api.ps1
```

This script:

- creates `.venv311`
- installs the API requirements
- installs standalone Keras 3 for compatibility with these `.h5` model files

## Run the API

```powershell
.\scripts\run_api.ps1
```

Default API URL:

- `http://127.0.0.1:8001`

Swagger docs:

- `http://127.0.0.1:8001/docs`

If port `8001` is already used:

```powershell
.\scripts\run_api.ps1 -Port 8002
```

## Test the API

Quick checks:

```powershell
Invoke-RestMethod http://127.0.0.1:8001/health
Invoke-RestMethod http://127.0.0.1:8001/info | ConvertTo-Json -Depth 5
```

Full test with an image:

```powershell
.\scripts\test_api.ps1 -ImagePath "C:\Users\YourName\Pictures\leaf.jpg"
```

Direct `curl.exe` examples:

```powershell
curl.exe -F 'file=@C:\Users\YourName\Pictures\leaf.jpg' http://127.0.0.1:8001/predict-disease
curl.exe -F 'file=@C:\Users\YourName\Pictures\leaf.jpg' 'http://127.0.0.1:8001/segment?threshold=0.5'
```

## API responses

`/predict-disease` returns JSON like:

```json
{
  "input_shape": [null, 224, 224, 3],
  "raw_output": [0.1, 0.2, 0.7],
  "predicted_index": 2,
  "predicted_score": 0.7
}
```

`/segment` returns JSON like:

```json
{
  "input_shape": [null, 256, 256, 3],
  "mask_png_base64": "..."
}
```

## Integrating with Flutter

Use the example file:

- `api/flutter_example.dart.txt`

Recommended Flutter packages:

```bash
flutter pub add http image_picker
```

What Flutter should do:

- pick or capture an image
- read image bytes
- send multipart form-data with field name `file`
- read the JSON result
- show `predicted_index` or map it to your own class labels
- decode `mask_png_base64` with `base64Decode(...)`
- display the mask using `Image.memory(...)`

Base URLs for Flutter:

- Android emulator: `http://10.0.2.2:8001`
- iOS simulator: `http://127.0.0.1:8001`
- Real Android/iPhone device: `http://YOUR_PC_LOCAL_IP:8001`

Example local IP:

- `http://192.168.1.10:8001`

For a real device:

- both devices must be on the same Wi-Fi network
- Windows Firewall must allow the chosen port
- run the API with `--host 0.0.0.0` which `run_api.ps1` already does

## Android notes

For local HTTP development, you may need cleartext traffic enabled in `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ... >
```

You also need internet permission:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## iOS notes

For local HTTP development, App Transport Security may block plain `http://` calls.

If needed, add an ATS exception in `ios/Runner/Info.plist` for local development.

## If you want labels instead of only class indexes

Right now the API returns:

- `predicted_index`
- `predicted_score`
- `raw_output`

If your classes are, for example, `healthy`, `early_disease`, `severe_disease`, you can map them in Flutter with a local list:

```dart
const labels = ['healthy', 'early_disease', 'severe_disease'];
final label = labels[result['predicted_index'] as int];
```

## Converting to TFLite later

If you decide to run the model directly inside Flutter instead of using the API:

```powershell
.\.venv311\Scripts\python.exe api\convert_to_tflite.py
```

This writes `.tflite` files next to the `.h5` files in `models/`.

## Adding the model files to GitHub with Git LFS later

If you want the branch itself to carry the models:

```powershell
git lfs install
git lfs track "models/*.h5"
git add .gitattributes
git add models\date_palm_disease_model.h5
git add models\unet_date_palm_segmentation.h5
git commit -m "Add palm tree model weights with Git LFS"
git push origin Palm_Tree_Model
```

## Recommended workflow for another PC

1. Clone the `Palm_Tree_Model` branch.
2. Place the two `.h5` files inside `models/`.
3. Run `.\scripts\setup_api.ps1`.
4. Run `.\scripts\run_api.ps1`.
5. Test with `.\scripts\test_api.ps1 -ImagePath "..."`
6. Point the Flutter app to the correct base URL for emulator or device.

## Troubleshooting

- `curl: (26) Failed to open/read local data from file/application`
  This means the image path is wrong. Use a full path.
- `No module named tensorflow`
  Use Python 3.11 and rerun `.\scripts\setup_api.ps1`.
- `/info` shows model errors
  Check that both `.h5` files exist in `models/` with the exact expected names.
- Flutter on a phone cannot connect
  Check the PC IP, the firewall, the Wi-Fi network, and the API port.
