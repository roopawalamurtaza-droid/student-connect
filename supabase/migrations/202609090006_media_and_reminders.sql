create function public.attach_media(p_target uuid,p_kind text,p_path text) returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=private.require_member(); asset public.media_assets;
begin
 select * into asset from public.media_assets where path=p_path and owner_id=uid;
 if not found then raise exception 'Invalid image ownership' using errcode='42501';end if;
 if p_kind='event' and asset.purpose='event' then
  if not exists(select 1 from public.events where id=p_target and (owner_id=uid or private.is_staff())) then raise exception 'Event owner access required' using errcode='42501';end if;
  update public.events set banner_path=p_path where id=p_target;
 elsif p_kind='community' and asset.purpose in ('community','club') then
  if not exists(select 1 from public.communities where id=p_target and (owner_id=uid or private.is_staff())) then raise exception 'Community owner access required' using errcode='42501';end if;
  update public.communities set image_path=p_path where id=p_target;
 else raise exception 'Invalid image purpose';end if;
end $$;
revoke all on function public.attach_media(uuid,text,text) from public,anon;
grant execute on function public.attach_media(uuid,text,text) to authenticated;
-- This database-only schedule creates in-app reminders without Firebase.
create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('student-connect-event-reminders','*/5 * * * *','select public.create_event_reminders()');
