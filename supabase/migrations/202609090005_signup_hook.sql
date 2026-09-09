create function public.before_user_created(event jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from private.allowed_email_domains where domain=lower(split_part(event->'user'->>'email','@',2))) then
  return jsonb_build_object('error',jsonb_build_object('http_code',403,'message','Use your approved university email address.'));
 end if;
 return '{}'::jsonb;
end $$;
revoke all on function public.before_user_created(jsonb) from public,anon,authenticated;
grant usage on schema public to supabase_auth_admin;
grant execute on function public.before_user_created(jsonb) to supabase_auth_admin;
