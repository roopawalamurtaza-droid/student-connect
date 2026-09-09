revoke all on function private.verified_identity(), private.active_member(), private.my_role(), private.is_staff(), private.visible_user(uuid) from public,anon;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('campus-media','campus-media',false,3145728,array['image/jpeg'])
on conflict(id) do update set public=false,file_size_limit=3145728,allowed_mime_types=array['image/jpeg'];
create policy campus_media_read on storage.objects for select to authenticated using(
 bucket_id='campus-media' and private.active_member() and exists(
 select 1 from public.media_assets m where m.path=name and private.visible_user(m.owner_id))
);
-- Uploads are accepted only by the image-processing Edge Function.
do $$ declare t text; begin
 foreach t in array array['profiles','user_roles','posts','post_media','comments','likes','saved_posts','communities','community_members','events','event_registrations','announcements','reports','notifications','blocked_users'] loop
  execute format('alter publication supabase_realtime add table public.%I',t);
 end loop;
end $$;

create function private.queue_push() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into private.push_outbox(user_id,title,body) values(new.user_id,new.title,new.body);
 return new;
end $$;
revoke all on function private.queue_push() from public,anon,authenticated;
create trigger notification_push after insert on public.notifications for each row execute function private.queue_push();

create function public.create_event_reminders() returns integer language plpgsql security definer set search_path='' as $$
declare n integer;
begin
 insert into public.notifications(user_id,title,body,link,kind,dedupe_key)
 select r.user_id,'Coming up: '||e.title,'Your event begins within an hour at '||e.location,e.id::text,'event','event:'||e.id||':'||r.user_id
 from public.event_registrations r join public.events e on e.id=r.event_id join public.profiles p on p.id=r.user_id
 where e.starts_at>now() and e.starts_at<=now()+interval '1 hour' and not p.suspended
 on conflict(dedupe_key) do nothing;
 get diagnostics n=row_count;return n;
end $$;
revoke all on function public.create_event_reminders() from public,anon,authenticated;
grant execute on function public.create_event_reminders() to service_role;

create function public.pending_pushes() returns jsonb language sql security definer set search_path='' as $$
 select coalesce(jsonb_agg(q),'[]') from (
 select o.id,o.title,o.body,array_agg(t.token) as tokens from private.push_outbox o
 join public.device_tokens t on t.user_id=o.user_id join public.profiles p on p.id=o.user_id
 where o.delivered_at is null and o.attempts<5 and not p.suspended
 group by o.id order by o.created_at limit 50) q;
$$;
create function public.finish_push(p_id uuid,p_delivered boolean) returns void language sql security definer set search_path='' as $$
 update private.push_outbox set attempts=attempts+1,delivered_at=case when p_delivered then now() else null end where id=p_id;
$$;
revoke all on function public.pending_pushes(),public.finish_push(uuid,boolean) from public,anon,authenticated;
grant execute on function public.pending_pushes(),public.finish_push(uuid,boolean) to service_role;
