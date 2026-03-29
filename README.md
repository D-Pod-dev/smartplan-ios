# SmartPlan (iOS)

SmartPlan is a local-first productivity app for tasks, projects, AI planning chat, focus sessions, and insights.

This implementation includes cloud sync contracts for **tasks**, **projects**, and **conversations** with a Supabase-backed architecture and placeholder environment variables.

## Stack

- SwiftUI (app UI)
- SwiftData (local persistence)
- `SmartPlanCore` package (business logic + sync contracts)

## Placeholder env vars

Set values in xcconfig files:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GROQ_BASE_URL`
- `GROQ_API_KEY`
- `GROQ_MODEL`

See `Config/Secrets.xcconfig.example`.

## Notes

- `project.yml` is provided for XcodeGen project generation.
- In this environment, XcodeGen is not installed, so project generation is not executed here.
- Core domain logic is testable via Swift Package tests (`swift test`).
