# Lingova persistent data

The production backend stores app data in normalized Supabase/PostgreSQL tables,
not local JSON files. This includes users, enrollments, payments, course
hierarchy, lessons, materials, support chat history, audio resources, community
posts, exams, exam attempts, progress, and certificates.

## Production setup with Supabase

1. Create a Supabase project.
2. Open the Supabase SQL editor.
3. Run `backend/supabase/schema.sql`.
4. Add these environment variables to Railway:

```text
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

The backend automatically switches to Supabase when both variables are present.
In this mode it reads and writes the normalized tables through SQL RPC
functions while preserving the current Flutter API response shape.

## Migrate existing JSON data

Run the migration once after creating the Supabase schema:

```bat
set "SUPABASE_URL=https://your-project.supabase.co"
set "SUPABASE_SERVICE_ROLE_KEY=your-service-role-key"
npm run migrate:supabase
```

If your current JSON files are not in `backend/data`, set:

```bat
set "LINGOVA_JSON_DATA_DIR=C:\Path\To\Existing\Data"
```

## File storage

The SQL creates a public Supabase Storage bucket named `lingova-audio`. Store
uploaded audio/video/document files there and save only the public file URL in
the app data. Do not store uploaded files inside the project folder or Railway
container.

## Local Windows/dev builds

If Supabase variables are not configured, local development falls back to JSON
files outside the project folder:

```text
%LOCALAPPDATA%\Lingova\backend-data
```

This keeps local test data available when you rebuild Flutter or replace the
project folder. On the first run, missing files are seeded from `backend/data`.

To choose a different folder, set `LINGOVA_DATA_DIR` before starting the
backend:

```bat
set "LINGOVA_DATA_DIR=D:\LingovaData"
npm start
```

## Railway fallback

Railway containers are rebuilt during deploys. Supabase is the recommended
production storage. If you temporarily use local JSON on Railway, add a
persistent volume and mount it at:

```text
/data
```

The server automatically uses `RAILWAY_VOLUME_MOUNT_PATH` when Railway provides
it, or `/data` when running on Railway. If Railway starts without a persistent
volume, the backend logs a warning because JSON data may be lost after redeploys.

For production, keep `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` configured
and treat Railway volumes only as a temporary fallback.
