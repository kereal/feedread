-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied

CREATE TABLE records(
  id INTEGER PRIMARY KEY,
  source_id INTEGER NOT NULL,
  uid VARCHAR NOT NULL,
  title VARCHAR NOT NULL,
  category VARCHAR,
  link VARCHAR NOT NULL,
  content TEXT,
  favorite BOOLEAN DEFAULT 0 NOT NULL,
  deleted BOOLEAN DEFAULT 0 NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
DROP TABLE records;
