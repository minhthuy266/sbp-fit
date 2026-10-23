-- SBP FIT Sprint 01: execute as database owner via Supabase CLI migrations or SQL editor.
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'Athlete' check (char_length(display_name) between 2 and 80),
 avatar_url text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.teams (
 id uuid primary key default gen_random_uuid(),
 name text not null check(char_length(name) between 2 and 80),
 slug text not null unique check (slug ~ '^[a-z0-9-]{3,40}$'),
 timezone text not null default 'Asia/Seoul',
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create table public.team_members (
 team_id uuid not null references public.teams(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'member' check(role in ('owner','admin','member')),
 status text not null default 'active' check(status in ('active','suspended')),
 joined_at timestamptz not null default now(),
 primary key(team_id,user_id)
);
create table public.team_invitations (
 id uuid primary key default gen_random_uuid(),
 team_id uuid not null references public.teams(id) on delete cascade,
 token_hash text not null unique,
 created_by uuid not null references auth.users(id),
 expires_at timestamptz not null,
 used_by uuid references auth.users(id),
 used_at timestamptz,
 created_at timestamptz not null default now(),
 constraint valid_use check ((used_by is null) = (used_at is null))
);
create index team_members_user_idx on public.team_members(user_id);
create index team_invitations_team_idx on public.team_invitations(team_id);
create or replace function public.bootstrap_profile() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles(id,display_name) values(new.id, left(coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'),''),split_part(new.email,'@',1),'Athlete'),80));
 return new;
end $$;
create trigger auth_user_created after insert on auth.users for each row execute function public.bootstrap_profile();
insert into public.profiles(id,display_name) select id,left(coalesce(nullif(trim(raw_user_meta_data->>'display_name'),''),split_part(email,'@',1),'Athlete'),80) from auth.users on conflict(id) do nothing;
-- SECURITY DEFINER helpers avoid recursively querying RLS-protected membership table.
create or replace function public.is_team_member(p_team_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.team_members where team_id=p_team_id and user_id=(select auth.uid()) and status='active');
$$;
create or replace function public.is_team_admin(p_team_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.team_members where team_id=p_team_id and user_id=(select auth.uid()) and status='active' and role in ('owner','admin'));
$$;
revoke all on function public.is_team_member(uuid) from public,anon;
revoke all on function public.is_team_admin(uuid) from public,anon;
grant execute on function public.is_team_member(uuid),public.is_team_admin(uuid) to authenticated;
alter table public.profiles enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.team_invitations enable row level security;
create policy profiles_read on public.profiles for select to authenticated using(id=(select auth.uid()) or exists(select 1 from public.team_members m where m.user_id=profiles.id and public.is_team_member(m.team_id)));
create policy profiles_update on public.profiles for update to authenticated using(id=(select auth.uid())) with check(id=(select auth.uid()));
create policy teams_select on public.teams for select to authenticated using(public.is_team_member(id));
create policy team_members_select on public.team_members for select to authenticated using(public.is_team_member(team_id));
create policy invitations_select on public.team_invitations for select to authenticated using(public.is_team_admin(team_id));
-- No client INSERT/UPDATE/DELETE grants through RLS; mutations must use vetted RPCs.
create or replace function public.create_team(p_name text,p_slug text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_id uuid; v_uid uuid := auth.uid();
begin
 if v_uid is null then raise exception 'Authentication required'; end if;
 p_name:=trim(p_name); p_slug:=trim(lower(p_slug));
 if char_length(p_name) not between 2 and 80 or p_slug !~ '^[a-z0-9-]{3,40}$' then raise exception 'Invalid team name or slug'; end if;
 insert into public.teams(name,slug,created_by) values(p_name,p_slug,v_uid) returning id into v_id;
 insert into public.team_members(team_id,user_id,role) values(v_id,v_uid,'owner');
 return v_id;
end $$;
create or replace function public.create_team_invite(p_team_id uuid,p_valid_days int default 7) returns text
language plpgsql security definer set search_path = '' as $$
declare v_token text; v_uid uuid:=auth.uid();
begin
 if v_uid is null or not public.is_team_admin(p_team_id) then raise exception 'Admin role required'; end if;
 if p_valid_days<1 or p_valid_days>30 then raise exception 'Expiry must be between 1 and 30 days'; end if;
 v_token:=encode(extensions.gen_random_bytes(24),'hex');
 insert into public.team_invitations(team_id,token_hash,created_by,expires_at)
 values(p_team_id,encode(extensions.digest(v_token,'sha256'),'hex'),v_uid,now()+make_interval(days=>p_valid_days));
 return v_token;
end $$;
create or replace function public.accept_team_invite(p_token text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare v_team_id uuid; v_uid uuid:=auth.uid(); v_invite_id uuid;
begin
 if v_uid is null then raise exception 'Authentication required'; end if;
 select id,team_id into v_invite_id,v_team_id from public.team_invitations
 where token_hash=encode(extensions.digest(trim(p_token),'sha256'),'hex') and expires_at>now() and used_at is null
 for update;
 if v_invite_id is null then raise exception 'Invite invalid, expired or already used'; end if;
 insert into public.team_members(team_id,user_id,role) values(v_team_id,v_uid,'member') on conflict(team_id,user_id) do update set status='active';
 update public.team_invitations set used_by=v_uid,used_at=now() where id=v_invite_id;
 return v_team_id;
end $$;
revoke all on function public.create_team(text,text),public.create_team_invite(uuid,int),public.accept_team_invite(text) from public,anon;
grant execute on function public.create_team(text,text),public.create_team_invite(uuid,int),public.accept_team_invite(text) to authenticated;
