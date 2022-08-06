-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied

INSERT INTO "main"."sources" ("id", "type", "title", "url", "ignore_categories", "active", "last_parsed_at", "created_at") VALUES ('1', 'atom', 'Rutracker', 'http://feed.rutracker.cc/atom/f/0.atom', NULL, '1', NULL, NULL);
INSERT INTO "main"."sources" ("id", "type", "title", "url", "ignore_categories", "active", "last_parsed_at", "created_at") VALUES ('2', 'rss', 'Habr', 'https://habr.com/ru/rss/best/daily/?fl=ru', NULL, '1', NULL, NULL);
INSERT INTO "main"."sources" ("id", "type", "title", "url", "ignore_categories", "active", "last_parsed_at", "created_at") VALUES ('3', 'rss', 'Mysku', 'https://mysku.club/rss/index', NULL, '1', NULL, NULL);
INSERT INTO "main"."sources" ("id", "type", "title", "url", "ignore_categories", "active", "last_parsed_at", "created_at") VALUES ('4', 'rss', 'Alexgyver', 'https://community.alexgyver.ru/forums/-/index.rss', NULL, '1', NULL, NULL);
INSERT INTO "main"."sources" ("id", "type", "title", "url", "ignore_categories", "active", "last_parsed_at", "created_at") VALUES ('5', 'rss', 'Vc', 'https://vc.ru/rss/all', NULL, '1', NULL, NULL);
INSERT INTO "main"."sources" ("id", "type", "title", "url", "ignore_categories", "active", "last_parsed_at", "created_at") VALUES ('6', 'rss', 'Linux.org.ru', 'https://www.linux.org.ru/section-rss.jsp?section=1', NULL, '1', NULL, NULL);
INSERT INTO "main"."sources" ("id", "type", "title", "url", "ignore_categories", "active", "last_parsed_at", "created_at") VALUES ('7', 'rss', 'Opennet', 'https://www.opennet.ru/opennews/opennews_all.rss', NULL, '1', NULL, NULL);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back

