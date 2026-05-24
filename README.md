# lingova_app

A new Flutter project.

## Backend data persistence

The Node backend stores chats, uploaded audio links, community posts, exams,
exam results, and certificate source data in Supabase/PostgreSQL when
`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are configured.

- Run `backend/supabase/schema.sql` in Supabase before enabling these variables.
- Run `npm run migrate:supabase` once to import existing `backend/data/*.json`.
- Local builds without Supabase still store data in
  `%LOCALAPPDATA%\Lingova\backend-data` by default.
- More details: [backend/PERSISTENT_DATA.md](backend/PERSISTENT_DATA.md)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
