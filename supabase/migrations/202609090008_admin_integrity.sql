create or replace function public.campus_mutate(action text,payload jsonb default '{}') returns jsonb language plpgsql security definer set search_path='' as $$
declare
 uid uuid; r public.campus_role; target uuid; department uuid; community uuid; asset uuid;
 post public.posts; ev public.events; c public.communities; new_id uuid; removed integer;
 data jsonb; message text; recipient uuid; role_target public.campus_role; target_role public.campus_role; start_time timestamptz;
begin
 if action='moderateUser' then perform pg_advisory_xact_lock(739021);end if;
 uid:=private.require_member(action='saveProfile');r:=coalesce(private.my_role(),'student');
 if jsonb_typeof(payload)<>'object' then raise exception 'Invalid request' using errcode='22023';end if;
 target:=nullif(payload->>'id','')::uuid;
 if action='saveProfile' then
  if payload-array['name','enrollment','department','semester','bio','skills']<>'{}'::jsonb then raise exception 'Unexpected profile field' using errcode='22023'; end if;
  if jsonb_typeof(payload->'skills')<>'array' or jsonb_array_length(payload->'skills')>12 or exists(select 1 from jsonb_array_elements(payload->'skills') s where jsonb_typeof(s)<>'string' or length(s#>>'{}') not between 1 and 40) then raise exception 'Use up to 12 skills, each 1 to 40 characters' using errcode='22023'; end if;
  insert into public.departments(name) values(private.clean_text(payload->>'department',80)) on conflict(name) do update set name=excluded.name returning id into department;
  insert into public.profiles(id,name,enrollment,department_id,semester,bio,skills)
   values(uid,private.clean_text(payload->>'name',80),private.clean_text(payload->>'enrollment',40),department,(payload->>'semester')::smallint,coalesce(payload->>'bio',''),array(select jsonb_array_elements_text(payload->'skills')))
   on conflict(id) do update set name=excluded.name,enrollment=excluded.enrollment,department_id=excluded.department_id,semester=excluded.semester,bio=excluded.bio,skills=excluded.skills,updated_at=now();
  insert into public.user_roles(user_id) values(uid) on conflict(user_id) do nothing;
 elsif action in ('createPost','editPost') then
  data:=case when action='editPost' then payload->'post' else payload end;
  message:=private.clean_text(data->>'body',3000);community:=nullif(data->>'communityId','')::uuid;
  if community is not null and not exists(select 1 from public.community_members where community_id=community and user_id=uid) then raise exception 'Join this community before posting' using errcode='42501';end if;
  if action='editPost' then
   select * into post from public.posts where id=target for update;
   if not found or post.author_id<>uid then raise exception 'You can only edit your own posts' using errcode='42501';end if;
   update public.posts set body=message,community_id=community,updated_at=now() where id=target;new_id:=target;
   delete from public.post_media where post_id=new_id;
  else insert into public.posts(author_id,community_id,body) values(uid,community,message) returning id into new_id;end if;
  if coalesce(data->>'imagePath','')<>'' then
   select id into asset from public.media_assets where path=data->>'imagePath' and owner_id=uid and purpose='post';
   if not found then raise exception 'Invalid image ownership' using errcode='42501';end if;
   insert into public.post_media(post_id,media_id) values(new_id,asset);
  end if;
 elsif action in ('deletePost','likePost','comment','savePost') then
  select * into post from public.posts where id=target for update;
  if not found then raise exception 'Post no longer exists' using errcode='P0002';end if;
  if not private.visible_user(post.author_id) and not private.is_staff() then raise exception 'Post unavailable' using errcode='42501';end if;
  if action='deletePost' then
   if post.author_id<>uid and not private.is_staff() then raise exception 'You cannot delete this post' using errcode='42501';end if;
   if post.author_id<>uid then insert into public.moderation_actions(actor_id,target_id,action) values(uid,target,action);end if;
   delete from public.posts where id=target;
  elsif action='likePost' then
   delete from public.likes where post_id=target and user_id=uid;get diagnostics removed=row_count;
   if removed=0 then
    insert into public.likes(post_id,user_id) values(target,uid);
    if post.author_id<>uid then insert into public.notifications(user_id,title,body,link,kind,dedupe_key) values(post.author_id,'New like',(select name from public.profiles where id=uid)||' liked your post.',target::text,'like','like:'||target||':'||uid) on conflict(dedupe_key) do nothing;end if;
   end if;
  elsif action='comment' then
   insert into public.comments(post_id,author_id,body) values(target,uid,private.clean_text(payload->>'body',1000)) returning id into new_id;
   if post.author_id<>uid then insert into public.notifications(user_id,title,body,link,kind,dedupe_key) values(post.author_id,'New comment',(select name from public.profiles where id=uid)||' commented on your post.',target::text,'comment','comment:'||new_id);end if;
  else
   delete from public.saved_posts where post_id=target and user_id=uid;get diagnostics removed=row_count;
   if removed=0 then insert into public.saved_posts(post_id,user_id) values(target,uid);end if;
  end if;
 elsif action='report' then
  message:=private.clean_text(payload->>'reason',1000);if length(message)<5 then raise exception 'Describe the concern in more detail' using errcode='22023';end if;
  case payload->>'kind'
   when 'posts' then select body into message from public.posts where id=target;
   when 'users' then select name into message from public.profiles where id=target;
   when 'events' then select title into message from public.events where id=target;
   when 'communities' then select name into message from public.communities where id=target;
   else raise exception 'Invalid report type' using errcode='22023';
  end case;
  if message is null then raise exception 'Reported content no longer exists' using errcode='P0002';end if;
  insert into public.reports(reporter_id,post_id,reported_user_id,event_id,community_id,target_kind,target_id,target_summary,reason) values(uid,case when payload->>'kind'='posts' then target end,case when payload->>'kind'='users' then target end,case when payload->>'kind'='events' then target end,case when payload->>'kind'='communities' then target end,payload->>'kind',target,message,payload->>'reason');
 elsif action='joinCommunity' then
  perform 1 from public.communities where id=target for update;if not found then raise exception 'Community no longer exists';end if;
  delete from public.community_members where community_id=target and user_id=uid;get diagnostics removed=row_count;
  if removed=0 then insert into public.community_members(community_id,user_id) values(target,uid);end if;
 elsif action='saveCommunity' then
  if r not in ('club_admin','moderator','faculty','admin','super_admin') then raise exception 'Community manager access required' using errcode='42501';end if;
  insert into public.communities(name,description,kind,owner_id) values(private.clean_text(payload->>'name',100),private.clean_text(payload->>'description',600),payload->>'kind',uid) returning id into new_id;
  insert into public.community_members(community_id,user_id) values(new_id,uid);
  if payload->>'kind'='Club' then insert into public.clubs(community_id) values(new_id);end if;
 elsif action='saveEvent' then
  if r not in ('club_admin','moderator','faculty','admin','super_admin') then raise exception 'Event manager access required' using errcode='42501';end if;
  data:=payload->'event';community:=nullif(data->>'communityId','')::uuid;start_time:=to_timestamp((data->>'startsAt')::double precision/1000);
  if start_time<=now() or start_time>now()+interval '1 year' then raise exception 'Choose a future date within one year' using errcode='22023';end if;
  if community is not null and not private.is_staff() and not exists(select 1 from public.communities where id=community and owner_id=uid) then raise exception 'Community owner access required' using errcode='42501';end if;
  if target is not null then
   select * into ev from public.events where id=target for update;
   if not found or (ev.owner_id is distinct from uid and not private.is_staff()) then raise exception 'You cannot edit this event' using errcode='42501';end if;
   update public.events set title=private.clean_text(data->>'title',120),description=private.clean_text(data->>'description',3000),location=private.clean_text(data->>'location',160),starts_at=start_time,community_id=community,updated_at=now() where id=target;
  else insert into public.events(owner_id,community_id,title,description,location,starts_at) values(uid,community,private.clean_text(data->>'title',120),private.clean_text(data->>'description',3000),private.clean_text(data->>'location',160),start_time) returning id into new_id;end if;
 elsif action in ('deleteEvent','registerEvent') then
  select * into ev from public.events where id=target for update;if not found then raise exception 'Event no longer exists';end if;
  if action='deleteEvent' then
   if ev.owner_id is distinct from uid and not private.is_staff() then raise exception 'You cannot delete this event' using errcode='42501';end if;
   delete from public.events where id=target;
  else
   if ev.starts_at<=now() then raise exception 'Event registration has closed';end if;
   delete from public.event_registrations where event_id=target and user_id=uid;get diagnostics removed=row_count;
   if removed=0 then insert into public.event_registrations(event_id,user_id) values(target,uid);end if;
  end if;
 elsif action='readNotification' then update public.notifications set read=true where id=target and user_id=uid;
 elsif action='saveToken' then
  insert into public.device_tokens(user_id,token) values(uid,private.clean_text(payload->>'token',4096)) on conflict(token) do update set user_id=uid,updated_at=now();
 elsif action='removeToken' then delete from public.device_tokens where user_id=uid and token=payload->>'token';
 elsif action='blockUser' then
  if target=uid then raise exception 'You cannot block yourself';end if;
  insert into public.blocked_users(blocker_id,blocked_id) values(uid,target) on conflict do nothing;
 elsif action='unblockUser' then delete from public.blocked_users where blocker_id=uid and blocked_id=target;
 elsif action='moderateUser' then
  if r not in ('admin','super_admin') then raise exception 'Administrator access required' using errcode='42501';end if;
  if target=uid then raise exception 'You cannot change your own access' using errcode='42501';end if;
  role_target:=(payload->>'role')::public.campus_role;select role into target_role from public.user_roles where user_id=target;
  if not found then raise exception 'User no longer exists';end if;
  if r<>'super_admin' and (role_target in ('admin','super_admin') or target_role in ('admin','super_admin')) then raise exception 'Only a super administrator can manage administrator access' using errcode='42501';end if;
  update public.user_roles set role=role_target,updated_at=now() where user_id=target;
  update public.profiles set suspended=(payload->>'suspended')::boolean,updated_at=now() where id=target;
  update auth.users set banned_until=case when (payload->>'suspended')::boolean then now()+interval '100 years' else null end where id=target;
  if (payload->>'suspended')::boolean then delete from public.device_tokens where user_id=target;end if;
  insert into public.moderation_actions(actor_id,target_id,action,details) values(uid,target,action,payload);
 elsif action='resolveReport' then
  if not private.is_staff() then raise exception 'Moderator access required' using errcode='42501';end if;
  update public.reports set status='resolved',resolved_by=uid,resolved_at=now() where id=target;
  insert into public.moderation_actions(actor_id,target_id,action) values(uid,target,action);
 elsif action='announce' then
  if not private.is_staff() then raise exception 'Moderator access required' using errcode='42501';end if;
  insert into public.announcements(author_id,title,body) values(uid,private.clean_text(payload->>'title',120),private.clean_text(payload->>'body',3000));
 elsif action='deleteAnnouncement' then
  if not private.is_staff() then raise exception 'Moderator access required' using errcode='42501';end if;
  delete from public.announcements where id=target;
 elsif action='prepareUpload' then return jsonb_build_object('uid',uid);
 else raise exception 'Unknown action' using errcode='22023';
 end if;
 return jsonb_build_object('ok',true,'id',new_id);
end $$;

-- Serialize role changes and retain at least one super administrator.
create function private.retain_super_admin() returns trigger language plpgsql security definer set search_path='' as $$
begin
 perform pg_advisory_xact_lock(739021);
 if old.role='super_admin' and (tg_op='DELETE' or new.role<>'super_admin') and not exists(select 1 from public.user_roles where role='super_admin' and user_id<>old.user_id) then raise exception 'Keep at least one super administrator.' using errcode='42501';end if;
 if tg_op='DELETE' then return old;else return new;end if;
end $$;
revoke all on function private.retain_super_admin() from public,anon,authenticated;
create trigger retain_super_admin before update or delete on public.user_roles for each row execute function private.retain_super_admin();
