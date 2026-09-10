-- Credentials are installed separately in Vault; none belong in migrations.
create extension if not exists pg_net with schema extensions;

create function private.dispatch_pending_pushes() returns bigint
language plpgsql security definer set search_path='' as $$
declare dispatch_secret text; project_url text;
begin
  if not exists (
    select 1 from private.push_outbox o
    join public.profiles p on p.id=o.user_id
    where o.delivered_at is null and o.attempts<5 and not p.suspended
      and exists(select 1 from public.device_tokens t where t.user_id=o.user_id)
  ) then return null; end if;
  select decrypted_secret into dispatch_secret from vault.decrypted_secrets
    where name='student_connect_push_dispatch';
  select decrypted_secret into project_url from vault.decrypted_secrets
    where name='student_connect_project_url';
  if dispatch_secret is null or project_url is null then return null; end if;
  return net.http_post(
    url:=project_url || '/functions/v1/dispatch-push',
    headers:=jsonb_build_object('Content-Type','application/json',
      'Authorization','Bearer ' || dispatch_secret),
    body:='{}'::jsonb, timeout_milliseconds:=10000);
end;
$$;
revoke all on function private.dispatch_pending_pushes() from public,anon,authenticated,service_role;

select cron.schedule('student-connect-push-dispatch','* * * * *',
  'select private.dispatch_pending_pushes();');
