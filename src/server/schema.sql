begin;

create table rules (
  id serial primary key,
  "from" text not null,
  to text not null,
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


create table devices (
  id serial primary key,
  name text not null,
  operating_system text not null,
  created_at timestamp  not null default now(),
  manufacturer_id integer not null references manufacturers(id),
  supported_card_readers text[] not null,
  supported_countries text[] not null
);

comment on table devices is 'Device models (e.g iPhone 7, S7)';
comment on column devices.id is 'Primary ID';
comment on column devices.name is 'The name of the model';
comment on column devices.operating_system is 'The operating system and version that the model runs (e.g iOS 7+)';


create function devices_by_country(country text) returns setof devices as $$
  select device.*
  from devices as device
  join manufacturers as manufacturers
  on device.manufacturer_id = manufacturers.id
  where supported_countries @> array[country]
  order by manufacturers.name asc, device.name asc
$$ language sql stable;

comment on function devices_by_country(text) is 'Get all devices by country code';


create function set_created_at() returns trigger as $$
begin
  new.created_at := current_timestamp;
  return new;
end;
$$ language plpgsql;

create trigger manufacturer_created_at before insert
  on manufacturers
  for each row
  execute procedure set_created_at();

commit;