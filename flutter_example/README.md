# Flutter Example

This folder contains a ready-to-drop Flutter example for the Satacenter Gabes backend.

## Files

- `lib/main.dart`: minimal app entrypoint
- `lib/services/satacenter_api.dart`: HTTP client for `/projects` and `/chat`
- `lib/models/chat_models.dart`: typed models for projects, chat turns, and sources
- `lib/screens/satacenter_chat_page.dart`: chat UI with project selector and source cards

## Packages to add

Add these dependencies to your Flutter `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  google_fonts: ^6.2.1
```

## How to use

1. Copy the `lib` files into your Flutter project.
2. Add the required dependencies.
3. Update the `baseUrl` in `lib/main.dart`.

Use:

- `http://10.0.2.2:8000` for Android emulator
- `http://127.0.0.1:8000` for desktop
- `http://<your-pc-lan-ip>:8000` for a physical phone on the same Wi-Fi

## Integration notes

- The screen uses `GET /projects` to load available projects.
- It sends chat history to `POST /chat`.
- Returned source cards show the project, page, score, and snippet for trust and explainability.
