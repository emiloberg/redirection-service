begin;

create table rules (
  id serial primary key,
  "from" text not null,
  "to" text not null,
  kind text not null,
  why text not null,
  who text not null,
  is_regex boolean not null,
  created timestamp not null default now(),
  updated timestamp not null default now()
);

comment on table rules is 'A redirection rule.';
comment on column rules.id is 'Primary ID.';
comment on column rules.from is 'Url slug or regex to match.';
comment on column rules.to is 'The destination. Where to redirect to.';
comment on column rules.kind is 'The kind of redirect: Temporary or Permanent.';
comment on column rules.why is 'The purpose of the rule.';
comment on column rules.who is 'Who made the rule.';
comment on column rules.is_regex is 'Should the "from"-column be treated as a regex?';
comment on column rules.created is 'The time of original creation.';
comment on column rules.updated is 'The time of the latest modification of the rule.';


create table users (
  id serial primary key,
  email text not null unique,
  google_id text not null unique,
  firstname text not null,
  lastname text not null,
  is_admin boolean not null default false,
  created timestamp not null default now()
);

comment on table users is 'A user of the system.';
comment on column users.id is 'Primary ID.';
comment on column users.email is 'The email used to log in with.';
comment on column users.google_id is 'The corresponding user id in Google apis.';
comment on column users.firstname is 'The given name.';
comment on column users.lastname is 'The family name.';
comment on column users.is_admin is 'Whether elevated privileges are granted to the user.';
comment on column users.created is 'The time of original creation.';

commit;
