CREATE TABLE IF NOT EXISTS projects(
    id SERIAL PRIMARY KEY,
    name VARCHAR(1024) NOT NULL,
    uuid VARCHAR(1024) NOT NULL);