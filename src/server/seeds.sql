begin;

insert into rules("from", "to", created, updated, kind, why, who, is_regex) values
('/tjejer-kodar-todo', 'http://izettle.github.io/tjejer-kodar-todo-app/', '2015-10-22 20:50:42.095188', '2016-09-01 13:16:21.390641', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/faq', '/help', '2016-08-15 14:49:03.870854', '2016-08-15 14:49:03.870854', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/wtf', '/help', '2016-08-15 14:49:47.954669', '2016-08-15 14:49:47.954669', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/hilfe', '/de/help', '2014-10-07 12:08:48.448222', '2015-03-30 13:17:33.129857', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/uk', '/gb', '2014-10-07 12:08:45.350255', '2014-10-07 12:08:45.350255', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/static/izettle_iphone3', 'http://izettle-static.s3.amazonaws.com/movies/izettle_iphone3.mov', '2014-10-07 12:08:46.591139', '2014-10-07 12:08:46.591139', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/static/izettle_iphone4', 'http://izettle-static.s3.amazonaws.com/movies/izettle_iphone4.mov', '2014-10-07 12:08:49.846212', '2014-10-07 12:08:49.846212', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/nl/kerstmis', '/nl', '2014-11-27 09:34:18.943445', '2014-11-27 09:34:18.943445', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/mxcostco', '/mx/costco', '2015-09-17 15:35:37.91466', '2015-09-17 15:42:52.456354', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/mxvisa', '/mx/visa', '2015-09-17 15:43:49.924489', '2015-09-17 15:43:49.924489', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/tjejer-kodar', 'https://izettle.github.io/tjejer-kodar-hardware-course/', '2016-09-01 13:16:31.443879', '2016-09-01 13:16:31.443879', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/se/epos', '/se/epos-kassasystem-for-restaurang-bar-cafe', '2017-04-19 14:58:25.264103', '2017-04-19 14:58:25.264103', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/fi/epos', '/fi/epos-kassajarjestelma-ravintoloille', '2017-04-19 15:01:16.927132', '2017-04-19 15:01:16.927132', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/gb/epos', '/gb/epos-for-restaurants-bars-cafes', '2017-04-19 15:01:44.793394', '2017-04-19 15:01:44.793394', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/dk/epos', '/dk/epos-kassesystem-til-restaurant-bar-cafe', '2017-04-19 15:02:05.746029', '2017-04-19 15:02:05.746029', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/gb/card-reader', '/gb/card-readers', '2017-04-21 11:23:00.277246', '2017-04-21 11:23:00.277246', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/Gb/service', '/gb/pos', '2017-08-02 07:41:43.379851', '2017-08-02 07:41:43.379851', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', false),
('/{country}/terms-old', '/$1/terms', '2016-06-22 12:56:40.800135', '2016-06-22 12:56:40.800135', 'Permanent', 'Migrated from Mission Control', 'admin@izettle.com', true);
commit;
