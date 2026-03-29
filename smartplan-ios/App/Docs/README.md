# SmartPlan iOS

SmartPlan is a SwiftUI + SwiftData iOS app with local-first persistence and optional cloud sync.

## Environment placeholders

Project configuration expects these values through `.xcconfig`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GROQ_BASE_URL`
- `GROQ_API_KEY`
- `GROQ_MODEL`

Use `Config/Secrets.xcconfig.example` as a template for your real secrets file.

## Cloud sync scope

Cloud sync is implemented for:

- Tasks
- Projects
- Conversations

Sync behavior:

- Initial sign-in bootstrap prefers remote data.
- If remote is empty and local has data, local is uploaded.
- Tasks sync immediately (replace strategy).
- Projects and conversations sync with debounce.

## Generate Xcode project

This repo includes an `xcodegen` spec (`project.yml`).

1. Install xcodegen
2. Run `xcodegen generate`
3. Open `SmartPlan.xcodeproj`
