-- Invoker rights preserve row policies. Explicit visibility also excludes blocked
-- or suspended profiles from discovery for staff who can otherwise moderate them.
create function public.search_students(search_text text default '', department_name text default '', semester_number int default null, page_offset int default 0, page_size int default 30)
returns setof jsonb language sql stable security invoker set search_path='' as $$
 select to_jsonb(p) || jsonb_build_object('departments',jsonb_build_object('name',d.name))
 from public.profiles p join public.departments d on d.id=p.department_id
 where private.active_member() and private.visible_user(p.id) and not p.suspended
 and (coalesce(department_name,'')='' or d.name=department_name)
 and (semester_number is null or p.semester=semester_number)
 and (coalesce(trim(search_text),'')='' or
   strpos(lower(concat_ws(' ',p.name,p.bio,d.name,array_to_string(p.skills,' '))),lower(trim(search_text)))>0)
 order by lower(p.name),p.id
 limit least(greatest(coalesce(page_size,30),1),100)
 offset least(greatest(coalesce(page_offset,0),0),100000)
$$;
revoke all on function public.search_students(text,text,int,int,int) from public,anon;
grant execute on function public.search_students(text,text,int,int,int) to authenticated;
