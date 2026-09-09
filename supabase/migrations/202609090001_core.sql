-- Student Connect: normalized application schema. Supabase Auth owns identity.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create type public.campus_role as enum ('student','club_admin','moderator','faculty','admin','super_admin');
create table private.allowed_email_domains (domain text primary key check (domain=lower(domain) and domain !~ '[@ /]'));
-- Deliberately empty: a university domain must be configured by an operator.
create table public.departments (id uuid primary key default gen_random_uuid(), name text not null unique check(length(name) between 1 and 80));
create table public.programs (id uuid primary key default gen_random_uuid(), department_id uuid not null references public.departments(id), name text not null check(length(name) between 1 and 100), unique(department_id,name));
create table public.semesters (id smallint primary key check(id between 1 and 12));
insert into public.semesters select generate_series(1,12);
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null check(length(name) between 1 and 80),
 enrollment text not null unique check(length(enrollment) between 1 and 40),
 department_id uuid not null references public.departments(id),
 program_id uuid references public.programs(id), semester smallint not null references public.semesters(id),
 bio text not null default '' check(length(bio)<=500), skills text[] not null default '{}' check(cardinality(skills)<=12),
 avatar_path text not null default '', suspended boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.user_roles (user_id uuid primary key references public.profiles(id) on delete cascade, role public.campus_role not null default 'student', updated_at timestamptz not null default now());
create table public.media_assets (id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id) on delete cascade, path text not null unique, purpose text not null check(purpose in ('avatar','post','community','club','event')), mime_type text not null check(mime_type='image/jpeg'), size_bytes integer not null check(size_bytes between 1 and 3145728), created_at timestamptz not null default now());
create table public.communities (id uuid primary key default gen_random_uuid(), name text not null unique check(length(name) between 1 and 100), description text not null check(length(description) between 1 and 600), kind text not null check(kind in ('Club','Department','Community')), owner_id uuid references public.profiles(id) on delete set null, image_path text not null default '', created_at timestamptz not null default now());
create table public.community_members (community_id uuid not null references public.communities(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade, created_at timestamptz not null default now(), primary key(community_id,user_id));
-- Clubs are a community subtype; membership is shared, rather than duplicated.
create table public.clubs (community_id uuid primary key references public.communities(id) on delete cascade, faculty_advisor_id uuid references public.profiles(id) on delete set null);
create table public.posts (id uuid primary key default gen_random_uuid(), author_id uuid not null references public.profiles(id) on delete cascade, community_id uuid references public.communities(id) on delete cascade, body text not null check(length(btrim(body)) between 1 and 3000), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.post_media (post_id uuid not null references public.posts(id) on delete cascade, media_id uuid not null references public.media_assets(id) on delete cascade, position smallint not null default 0 check(position between 0 and 9), primary key(post_id,media_id),unique(post_id,position));
create table public.comments (id uuid primary key default gen_random_uuid(), post_id uuid not null references public.posts(id) on delete cascade, author_id uuid not null references public.profiles(id) on delete cascade, body text not null check(length(btrim(body)) between 1 and 1000), created_at timestamptz not null default now());
create table public.likes (post_id uuid not null references public.posts(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,created_at timestamptz not null default now(),primary key(post_id,user_id));
create table public.saved_posts (post_id uuid not null references public.posts(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,created_at timestamptz not null default now(),primary key(post_id,user_id));
create table public.events (id uuid primary key default gen_random_uuid(),owner_id uuid references public.profiles(id) on delete set null,community_id uuid references public.communities(id) on delete cascade,title text not null check(length(btrim(title)) between 1 and 120),description text not null check(length(description) between 1 and 3000),location text not null check(length(location) between 1 and 160),starts_at timestamptz not null,banner_path text not null default '',created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create table public.event_registrations (event_id uuid not null references public.events(id) on delete cascade,user_id uuid not null references public.profiles(id) on delete cascade,reminder_sent boolean not null default false,created_at timestamptz not null default now(),primary key(event_id,user_id));
create table public.announcements (id uuid primary key default gen_random_uuid(),author_id uuid references public.profiles(id) on delete set null,title text not null check(length(btrim(title)) between 1 and 120),body text not null check(length(btrim(body)) between 1 and 3000),created_at timestamptz not null default now());
create table public.reports (id uuid primary key default gen_random_uuid(),reporter_id uuid references public.profiles(id) on delete set null,post_id uuid references public.posts(id) on delete set null,reported_user_id uuid references public.profiles(id) on delete set null,event_id uuid references public.events(id) on delete set null,community_id uuid references public.communities(id) on delete set null,target_kind text not null check(target_kind in ('posts','users','events','communities')),target_id uuid not null,target_summary text not null default '',reason text not null check(length(btrim(reason)) between 5 and 1000),status text not null default 'open' check(status in ('open','resolved')),resolved_by uuid references public.profiles(id) on delete set null,created_at timestamptz not null default now(),resolved_at timestamptz);
create table public.moderation_actions (id uuid primary key default gen_random_uuid(),actor_id uuid references public.profiles(id) on delete set null,target_id uuid,action text not null,details jsonb not null default '{}',created_at timestamptz not null default now());
create table public.notifications (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,title text not null,body text not null,link text not null default '',kind text not null,dedupe_key text unique,read boolean not null default false,created_at timestamptz not null default now());
create table public.device_tokens (user_id uuid not null references public.profiles(id) on delete cascade,token text not null unique check(length(token) between 20 and 4096),updated_at timestamptz not null default now(),primary key(user_id,token));
create table public.blocked_users (blocker_id uuid not null references public.profiles(id) on delete cascade,blocked_id uuid not null references public.profiles(id) on delete cascade,created_at timestamptz not null default now(),primary key(blocker_id,blocked_id),check(blocker_id<>blocked_id));
create table private.request_limits (user_id uuid primary key references auth.users(id) on delete cascade,window_start timestamptz not null default now(),request_count integer not null default 1);
create table private.push_outbox (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id) on delete cascade,title text not null,body text not null,created_at timestamptz not null default now(),delivered_at timestamptz,attempts integer not null default 0);

create index profiles_department_idx on public.profiles(department_id);
create index programs_department_idx on public.programs(department_id);
create index profiles_program_idx on public.profiles(program_id);
create index posts_latest_idx on public.posts(created_at desc,id);
create index posts_author_idx on public.posts(author_id);
create index posts_community_idx on public.posts(community_id,created_at desc);
create index posts_search_idx on public.posts using gin(to_tsvector('simple',body));
create index profiles_search_idx on public.profiles using gin(to_tsvector('simple',name||' '||bio));
create index community_members_user_idx on public.community_members(user_id);
create index communities_owner_idx on public.communities(owner_id);
create index media_owner_idx on public.media_assets(owner_id);
create index post_media_asset_idx on public.post_media(media_id);
create index comments_post_idx on public.comments(post_id,created_at);
create index comments_author_idx on public.comments(author_id);
create index likes_user_idx on public.likes(user_id);
create index saved_posts_user_idx on public.saved_posts(user_id);
create index events_time_idx on public.events(starts_at,id);
create index events_owner_idx on public.events(owner_id);
create index events_community_idx on public.events(community_id);
create index event_registration_user_idx on public.event_registrations(user_id);
create index notifications_user_idx on public.notifications(user_id,created_at desc);
create index blocked_users_reverse_idx on public.blocked_users(blocked_id,blocker_id);
create index reports_open_idx on public.reports(status,created_at);
create index moderation_actor_idx on public.moderation_actions(actor_id);
create index outbox_pending_idx on private.push_outbox(created_at) where delivered_at is null;

create function private.verified_identity() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from auth.users u join private.allowed_email_domains d on d.domain=lower(split_part(u.email,'@',2)) where u.id=auth.uid() and u.email_confirmed_at is not null and (u.banned_until is null or u.banned_until<now()));
$$;
create function private.active_member() returns boolean language sql stable security definer set search_path='' as $$ select private.verified_identity() and exists(select 1 from public.profiles where id=auth.uid() and not suspended); $$;
create function private.my_role() returns public.campus_role language sql stable security definer set search_path='' as $$ select role from public.user_roles where user_id=auth.uid(); $$;
create function private.is_staff() returns boolean language sql stable security definer set search_path='' as $$ select private.active_member() and private.my_role() in ('moderator','faculty','admin','super_admin'); $$;
create function private.visible_user(other uuid) returns boolean language sql stable security definer set search_path='' as $$ select not exists(select 1 from public.blocked_users where (blocker_id=auth.uid() and blocked_id=other) or (blocker_id=other and blocked_id=auth.uid())); $$;
-- These helpers are callable by policy evaluation but private is not an exposed API schema.
grant usage on schema private to authenticated;
grant execute on function private.verified_identity(), private.active_member(), private.my_role(), private.is_staff(), private.visible_user(uuid) to authenticated;

do $$ declare t text; begin
 foreach t in array array['departments','programs','semesters','profiles','user_roles','media_assets','communities','community_members','clubs','posts','post_media','comments','likes','saved_posts','events','event_registrations','announcements','reports','moderation_actions','notifications','device_tokens','blocked_users'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from anon, authenticated',t);
  execute format('grant select on public.%I to authenticated',t);
 end loop;
end $$;
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid() or (private.active_member() and (private.visible_user(id) or private.is_staff())));
create policy role_read on public.user_roles for select to authenticated using(user_id=auth.uid() or private.active_member());
create policy department_read on public.departments for select to authenticated using(private.verified_identity());
create policy program_read on public.programs for select to authenticated using(private.verified_identity());
create policy semester_read on public.semesters for select to authenticated using(private.verified_identity());
create policy media_read on public.media_assets for select to authenticated using(private.active_member() and private.visible_user(owner_id));
create policy community_read on public.communities for select to authenticated using(private.active_member());
create policy membership_read on public.community_members for select to authenticated using(private.active_member());
create policy club_read on public.clubs for select to authenticated using(private.active_member());
create policy post_read on public.posts for select to authenticated using(private.active_member() and (private.visible_user(author_id) or private.is_staff()));
create policy post_media_read on public.post_media for select to authenticated using(exists(select 1 from public.posts where id=post_id));
create policy comment_read on public.comments for select to authenticated using(private.active_member() and private.visible_user(author_id) and exists(select 1 from public.posts where id=post_id));
create policy like_read on public.likes for select to authenticated using(private.active_member() and exists(select 1 from public.posts where id=post_id));
create policy saved_read on public.saved_posts for select to authenticated using(private.active_member() and user_id=auth.uid());
create policy event_read on public.events for select to authenticated using(private.active_member());
create policy registration_read on public.event_registrations for select to authenticated using(private.active_member() and (user_id=auth.uid() or private.is_staff()));
create policy announcement_read on public.announcements for select to authenticated using(private.active_member());
create policy report_read on public.reports for select to authenticated using(private.is_staff());
create policy moderation_read on public.moderation_actions for select to authenticated using(private.is_staff());
create policy notification_read on public.notifications for select to authenticated using(private.active_member() and user_id=auth.uid());
create policy tokens_read on public.device_tokens for select to authenticated using(private.active_member() and user_id=auth.uid());
create policy blocked_read on public.blocked_users for select to authenticated using(private.active_member() and blocker_id=auth.uid());
-- No direct client write grants or policies: writes use checked transactional RPCs.

create function private.require_member(allow_onboarding boolean default false) returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); counter integer;
begin
 if uid is null or not private.verified_identity() then raise exception 'A verified university email is required' using errcode='42501'; end if;
 if exists(select 1 from public.profiles where id=uid and suspended) then raise exception 'Account suspended. Contact your university.' using errcode='42501'; end if;
 if not allow_onboarding and not private.active_member() then raise exception 'Complete your profile first' using errcode='42501'; end if;
 insert into private.request_limits as r(user_id) values(uid) on conflict(user_id) do update set window_start=case when r.window_start<now()-interval '1 minute' then now() else r.window_start end, request_count=case when r.window_start<now()-interval '1 minute' then 1 else r.request_count+1 end returning request_count into counter;
 if counter>30 then raise exception 'Too many requests. Try again in a minute.' using errcode='P0001'; end if;
 return uid;
end $$;
revoke all on function private.require_member(boolean) from public,anon,authenticated;
revoke all on all tables in schema private from anon,authenticated;
