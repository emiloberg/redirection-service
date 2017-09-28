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

comment on table rules is 'List of redirection rules.';
comment on column rules.id is 'Primary ID.';
comment on column rules.from is 'Url slug or regex to match.';
comment on column rules.to is 'The destination. Where to redirect to.';
comment on column rules.kind is 'The kind of redirect: Temporary or Permanent.';
comment on column rules.why is 'The purpose of the rule.';
comment on column rules.who is 'Who made the rule.';
comment on column rules.is_regex is 'Should the "from"-column be treated as a regex?';
comment on column rules.created is 'The time of original creation.';
comment on column rules.updated is 'The time of the latest modification of the rule.';

commit;