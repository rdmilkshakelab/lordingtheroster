-- Shared progress image uploads for Lording the Roster.
-- Run this in Supabase SQL Editor. Only verified allow-listed admins can upload,
-- replace or delete images. Images are publicly viewable with the tracker.
alter table public.hero_progress
  add column if not exists image_url text not null default '';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'hero-progress-images',
  'hero-progress-images',
  true,
  8388608,
  array['image/jpeg','image/png','image/webp','image/gif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public can view hero progress images" on storage.objects;
create policy "Public can view hero progress images"
on storage.objects for select
to public
using (bucket_id = 'hero-progress-images');

drop policy if exists "Verified admins can upload hero progress images" on storage.objects;
create policy "Verified admins can upload hero progress images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'hero-progress-images'
  and public.ltr_is_admin()
  and (auth.jwt() ->> 'aal') = 'aal2'
);

drop policy if exists "Verified admins can update hero progress images" on storage.objects;
create policy "Verified admins can update hero progress images"
on storage.objects for update
to authenticated
using (
  bucket_id = 'hero-progress-images'
  and public.ltr_is_admin()
  and (auth.jwt() ->> 'aal') = 'aal2'
)
with check (
  bucket_id = 'hero-progress-images'
  and public.ltr_is_admin()
  and (auth.jwt() ->> 'aal') = 'aal2'
);

drop policy if exists "Verified admins can delete hero progress images" on storage.objects;
create policy "Verified admins can delete hero progress images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'hero-progress-images'
  and public.ltr_is_admin()
  and (auth.jwt() ->> 'aal') = 'aal2'
);
