-- Drafts and replaced images remain visible only to their owner.
create function private.visible_media(asset_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.active_member() and exists(select 1 from public.media_assets m where m.id=asset_id and (
 m.owner_id=auth.uid() or (private.visible_user(m.owner_id) and (
 exists(select 1 from public.profiles p where p.id=m.owner_id and p.avatar_path=m.path)
 or exists(select 1 from public.post_media pm join public.posts p on p.id=pm.post_id where pm.media_id=m.id and private.visible_user(p.author_id))
 or exists(select 1 from public.communities c where c.image_path=m.path)
 or exists(select 1 from public.events e where e.banner_path=m.path)))));
$$;
revoke all on function private.visible_media(uuid) from public,anon;
grant execute on function private.visible_media(uuid) to authenticated;
drop policy media_read on public.media_assets;
create policy media_read on public.media_assets for select to authenticated using(private.visible_media(id));
create unique index enrollment_case_insensitive_idx on public.profiles(lower(enrollment));
create or replace function public.register_media(p_user_id uuid,p_path text,p_purpose text,p_size integer) returns void language plpgsql security definer set search_path='' as $$
begin
 perform 1 from public.profiles where id=p_user_id and not suspended for update;
 if not found or p_path not like p_user_id::text||'/%' then raise exception 'Invalid media owner';end if;
 if (select coalesce(sum(size_bytes),0) from public.media_assets where owner_id=p_user_id)+p_size>104857600 then raise exception 'Your media storage limit has been reached.';end if;
 insert into public.media_assets(owner_id,path,purpose,mime_type,size_bytes) values(p_user_id,p_path,p_purpose,'image/jpeg',p_size);
 if p_purpose='avatar' then update public.profiles set avatar_path=p_path where id=p_user_id;end if;
end $$;
