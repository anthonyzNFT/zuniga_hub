-- Zuniga family hub — v0 schema
-- Family-only. Google identity proves who you are; this app owns the session.
-- Allowlist is enforced in app code, not just the unique email constraint.

create extension if not exists pgcrypto;

-- ---------- users ----------
create table users (
  id uuid primary key default gen_random_uuid(),
  google_sub text unique not null,
  email text unique not null,
  display_name text not null,
  avatar_url text,
  bio text,                          -- short line under the name on Me
  status text,                       -- "at the park", "working late"
  status_updated_at timestamptz,
  theme text not null default 'system',          -- system | light | dark
  accent text not null default 'terracotta',     -- family accent, per person
  notif_replies boolean not null default true,
  notif_events boolean not null default true,
  notif_reminders boolean not null default true,
  notif_digest boolean not null default true,
  digest_hour smallint not null default 8,       -- local hour, 0-23
  timezone text not null default 'America/Los_Angeles',
  quiet_start time,                              -- optional do-not-disturb
  quiet_end time,
  created_at timestamptz not null default now()
);

-- ---------- posts (the feed) ----------
-- A reply is a post with parent_id set. Flat threads only — no nesting.
create table posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references users(id),
  parent_id uuid references posts(id) on delete cascade,
  body text,
  image_url text,
  instagram_url text,
  instagram_embed_html text,         -- cached oEmbed; never re-fetched on scroll
  embed_cached_at timestamptz,
  created_at timestamptz not null default now(),
  constraint post_has_content check (
    body is not null or image_url is not null or instagram_url is not null
  )
);

create index posts_feed on posts (created_at desc) where parent_id is null;
create index posts_replies on posts (parent_id, created_at);
create index posts_by_author on posts (author_id, created_at desc);

-- ---------- asks (the "what are you doing today" broadcast) ----------
-- Lives in the feed and also fans out as a notification.
-- Cap is per person per week so it cannot become a second group chat.
create table asks (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references users(id),
  message text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours')
);

create table ask_responses (
  ask_id uuid not null references asks(id) on delete cascade,
  user_id uuid not null references users(id),
  response text not null check (response in ('in', 'later', 'out')),
  note text,
  created_at timestamptz not null default now(),
  primary key (ask_id, user_id)
);

create table ask_usage (
  user_id uuid not null references users(id),
  week_start date not null,          -- Monday, user timezone
  used smallint not null default 0,
  cap smallint not null default 3,
  primary key (user_id, week_start)
);

-- ---------- events ----------
create table events (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references users(id),
  title text not null,
  description text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  location text,
  website text,
  color text not null default '#c45c26',
  banner_url text,
  created_at timestamptz not null default now()
);

create index events_by_time on events (starts_at);

create table event_rsvps (
  event_id uuid not null references events(id) on delete cascade,
  user_id uuid not null references users(id),
  status text not null check (status in ('going', 'maybe', 'no')),
  updated_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

-- A reminder nudge only targets people with no RSVP. Sender cannot spam:
-- one reminder per event per 12 hours.
create table event_reminders (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references events(id) on delete cascade,
  sent_by uuid not null references users(id),
  sent_at timestamptz not null default now()
);

-- ---------- profile links (manual, not scraped) ----------
create table social_links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  platform text not null check (platform in ('instagram', 'facebook', 'tiktok', 'x')),
  url text not null,
  unique (user_id, platform)
);

-- ---------- notifications ----------
-- This is the Notifications tab. Not a separate product surface.
-- type: reply | ask | event_invite | event_reminder | digest
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id),
  type text not null,
  actor_id uuid references users(id),
  post_id uuid references posts(id) on delete cascade,
  ask_id uuid references asks(id) on delete cascade,
  event_id uuid references events(id) on delete cascade,
  payload jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_inbox on notifications (user_id, created_at desc);
create index notifications_unread on notifications (user_id) where read_at is null;
