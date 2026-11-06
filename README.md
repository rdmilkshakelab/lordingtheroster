# Lording the Roster

A responsive GitHub Pages tracker for the Marvel Rivals challenge: reach **Lord** proficiency on every hero.

## Features

- Full 54-hero roster (as of November 2026), with role filters and search.
- Track each hero's status, proficiency level, episode number, video URL and notes.
- Dashboard with Lord count, completion percentage and current challenge.
- Random next-hero picker.
- JSON export/import backup.
- Community suggestion form.
- Optional Supabase connection for a shared suggestion board.

Progress is saved in the visitor's browser using localStorage. It is not automatically synchronised between devices.

## Deploy with GitHub Pages

1. Open **Settings → Pages** in this repository.
2. Under **Build and deployment**, choose **GitHub Actions** as the source.
3. The workflow in `.github/workflows/pages.yml` deploys the site after pushes to `main`.
4. The site URL will be `https://rdmilkshakelab.github.io/lordingtheroster/`.

## Shared community suggestions

1. Create a Supabase project.
2. Open the Supabase SQL Editor and run the contents of [supabase/schema.sql](supabase/schema.sql).
3. In the site, open **Settings → Shared community board**.
4. Paste the project URL and the anon/publishable key.

**Never paste a Supabase service-role key into the website.** The browser must only use the public anon/publishable key, protected by Row Level Security.

The current public Supabase setup supports shared suggestion submissions and reading. Shared voting and moderation are not enabled yet. They need a secure vote endpoint and an authenticated admin flow; this is deliberately not faked with a client-side counter.

## Admin login with an authenticator app

The site supports an admin account protected by TOTP multi-factor authentication. Google Authenticator, Microsoft Authenticator, 1Password and other compatible authenticator apps work.

1. Create a Supabase project and run the **entire** `supabase/schema.sql` file in the SQL Editor.
2. In Supabase, open **Authentication → Users** and create your admin user with an email and password. Keep those credentials private.
3. Copy that user's UUID from the Users list.
4. In the SQL Editor, grant that specific account admin access:

   ```sql
   insert into public.ltr_admins(user_id)
   values ('PASTE-YOUR-AUTH-USER-UUID-HERE');
   ```

5. In the website's **Settings**, save the Supabase project URL and public anon/publishable key.
6. Under **Admin login & authenticator**, sign in with the email and password you created.
7. Select **Set up authenticator**, scan the QR code using Google Authenticator (or another TOTP app), then enter the six-digit code to verify.
8. Once verified, use the hero cards' **Edit** controls to change statuses, levels, episode links and notes. Changes are stored in Supabase and shared with visitors.

The database only permits accounts listed in `ltr_admins` to update shared hero progress, and requires the Supabase session to be at MFA assurance level `aal2`. The browser cannot grant itself admin status. Do not add public visitors to `ltr_admins`, and never put a service-role key in the website.

If you lose access to your authenticator, use Supabase's trusted account recovery process from the project dashboard. Do not delete the MFA factor casually, as it protects the admin account.

## Updating the roster

The roster is defined near the top of the inline script in `index.html` as `ROSTER`. Update it when Marvel Rivals adds heroes or role changes. Deadpool is intentionally listed once with all three roles.

## Project status

This is a fan-made community project and is not affiliated with Marvel, NetEase or Marvel Rivals.
