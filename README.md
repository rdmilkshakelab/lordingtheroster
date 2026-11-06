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

## Updating the roster

The roster is defined near the top of the inline script in `index.html` as `ROSTER`. Update it when Marvel Rivals adds heroes or role changes. Deadpool is intentionally listed once with all three roles.

## Project status

This is a fan-made community project and is not affiliated with Marvel, NetEase or Marvel Rivals.
