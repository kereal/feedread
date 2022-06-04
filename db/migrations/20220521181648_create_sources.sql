-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied

CREATE TABLE sources(
  id INTEGER PRIMARY KEY,
  type TEXT NOT NULL,
  title VARCHAR NOT NULL,
  url VARCHAR NOT NULL,
  ignore_categories TEXT,
  active BOOLEAN DEFAULT 1 NOT NULL,
  last_parsed_at TIMESTAMP,
  created_at TIMESTAMP
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE sources;
