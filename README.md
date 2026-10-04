# مذاكرتي | Mzakeraty — Cloud Connected

نسخة ثنائية اللغة (العربية / English) من منصة مذاكرتي، مربوطة بمشروع Supabase الخاص بالمشروع.

## Cloud configuration
- Supabase URL: `https://glfjrtckirnmqfthshar.supabase.co`
- Uses the Supabase **Publishable key** in `config.js`.
- Never place a `sb_secret_...` / service-role key in the browser.

## Content permissions
- The owner/admin account can add, edit, delete subjects and lectures and upload lecture files.
- Signed-in students can read the shared learning library.
- Flashcards and questions are private per student.
- RLS in Supabase is the real security boundary; hiding buttons in the UI is not relied upon for security.

## Required Supabase setup
1. Run the supplied `supabase_schema.sql` in Supabase SQL Editor.
2. Create/sign in to the owner account.
3. Set `profiles.is_admin = true` for the owner account UUID.
4. Deploy this folder to an HTTPS host.

## Current scope
- Arabic/English UI and bilingual subject/lecture fields.
- Supabase Auth.
- Supabase database CRUD.
- Private lecture-file storage bucket with admin-only writes.
- Student read-only content access.
- PWA/service worker.
- Credit: Built & Crafted by loca_tove.
