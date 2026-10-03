# مذاكرتي | Mzakeraty — Vibrant Bilingual Cloud v4

## What changed
- New lively responsive dashboard and modern visual style.
- Arabic / English UI toggle.
- Arabic + English fields for subjects, lecture titles and notes.
- Owner-only content management: only accounts marked `is_admin=true` can add/edit/delete subjects and lectures or upload files.
- Signed-in users can read the shared library and open lecture files.
- Supabase RLS enforces the owner-only rule server-side. Hiding buttons is not the security mechanism.
- Private `lecture-files` storage bucket.

## First Supabase setup
1. Create a Supabase project.
2. Open SQL Editor and run `supabase_schema.sql`.
3. Create your account in the app.
4. In Supabase SQL Editor, find your user UUID in Authentication > Users, then run:
   `update public.profiles set is_admin=true where id='YOUR-USER-UUID';`
5. Put your project URL and anon/publishable key in `config.js`. Never put the service-role key in the browser.
6. Deploy the folder to an HTTPS host.

## Important
The bilingual fields are ready for future automatic translation/AI processing. The actual PDF/PPT translation should be handled by a secure server/AI endpoint later; do not expose an AI secret key in the browser.
