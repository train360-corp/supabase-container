CREATE TABLE test_table
(
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);