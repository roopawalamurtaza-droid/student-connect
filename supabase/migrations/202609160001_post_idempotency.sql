-- Receipts survive post deletion so a delayed retry cannot recreate deleted content.
create table private.post_publish_receipts (
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  result jsonb not null,
  primary key (user_id, request_id)
);
revoke all on private.post_publish_receipts from public, anon, authenticated;

alter function public.campus_mutate(text,jsonb) rename to campus_mutate_without_receipt;
alter function public.campus_mutate_without_receipt(text,jsonb) set schema private;
revoke all on function private.campus_mutate_without_receipt(text,jsonb) from public, anon, authenticated;

create function public.campus_mutate(action text,payload jsonb default '{}')
returns jsonb language plpgsql security definer set search_path='' as $$
declare member_id uuid; publish_request_id uuid; response jsonb;
begin
  if action <> 'createPost' or nullif(payload->>'requestId','') is null then
    return private.campus_mutate_without_receipt(action,payload);
  end if;
  member_id := private.require_member(false);
  publish_request_id := (payload->>'requestId')::uuid;
  -- Serialize retries for this member/request; unrelated requests remain independent.
  perform pg_advisory_xact_lock(hashtextextended(member_id::text || ':' || publish_request_id::text,0));
  select r.result into response from private.post_publish_receipts r
    where r.user_id=member_id and r.request_id=publish_request_id;
  if found then return response; end if;
  response := private.campus_mutate_without_receipt(action,payload-'requestId');
  insert into private.post_publish_receipts values(member_id,publish_request_id,response);
  return response;
end $$;
revoke all on function public.campus_mutate(text,jsonb) from public,anon;
grant execute on function public.campus_mutate(text,jsonb) to authenticated;
