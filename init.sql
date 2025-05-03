-- Create database
CREATE DATABASE partitioning_test;

-- Connect to the partitioning_test database
\connect partitioning_test

-- Create schema for partman
CREATE SCHEMA partman;

-- Create extensions (pg_cron now works since we set cron.database_name = 'partitioning_test')
CREATE EXTENSION IF NOT EXISTS pg_partman;
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS bloom;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;


-- Set search path
ALTER DATABASE partitioning_test SET search_path = public, partman;
SET search_path = public, partman;

-- Create tables
CREATE TABLE table_a (
    "timestamp" TIMESTAMP WITH TIME ZONE NOT NULL,
    id UUID NOT NULL,
    data TEXT,
    PRIMARY KEY (id)
);

-- Insert sample data
INSERT INTO table_a
SELECT
  NOW() - (i || ' days')::INTERVAL,
  gen_random_uuid(),
  'Sample data ' || i
FROM generate_series(1, 10000) i;

CREATE TABLE table_b_partitioned (
    "timestamp" TIMESTAMP WITH TIME ZONE NOT NULL,
    id UUID NOT NULL,
    data TEXT,
    PRIMARY KEY (id, "timestamp")
) PARTITION BY RANGE ("timestamp");

-- Use the correct named parameter syntax with => instead of :=
SELECT public.create_parent(
    p_parent_table => 'public.table_b_partitioned',
    p_control => 'timestamp',
    p_type => 'range',
    p_interval => '7 days',
    p_premake => 3,
    p_start_partition => date_trunc('week', current_date - interval '3 months')::text,
    p_default_table => FALSE
);

-- Drop and recreate earthquakes table
DROP TABLE IF EXISTS earthquakes;
CREATE TABLE earthquakes (
    id SERIAL PRIMARY KEY,
    content JSONB
);

-- Insert earthquake JSON data with nested location
INSERT INTO earthquakes (content) VALUES (
'{
  "features": [
    {
      "properties": {
        "title": "M 1.2 - 5km SW of Anza, CA",
        "mag": 1.2,
        "place": "5km SW of Anza, CA",
        "time": "2025-04-21T00:00:00Z",
        "url": "http://example.com/ci1",
        "detail": "http://example.com/detail/ci1",
        "felt": 2,
        "location": { "lat": 33.555, "lon": -116.673 }
      },
      "id": "ci1"
    },
    {
      "properties": {
        "title": "M 3.5 - 10km SE of Ridgecrest, CA",
        "mag": 3.5,
        "place": "10km SE of Ridgecrest, CA",
        "time": "2025-04-20T10:00:00Z",
        "url": "http://example.com/ci2",
        "detail": "http://example.com/detail/ci2",
        "felt": 5,
        "location": { "lat": 35.622, "lon": -117.67 }
      },
      "id": "ci2"
    }
  ]
}'
);

-- Drop and recreate regions table
DROP TABLE IF EXISTS regions;
CREATE TABLE regions (
    region_id SERIAL PRIMARY KEY,
    region_name TEXT,
    lat_min REAL,
    lat_max REAL,
    lon_min REAL,
    lon_max REAL
);

-- Insert regions
INSERT INTO regions (region_name, lat_min, lat_max, lon_min, lon_max) VALUES
('Southern California', 32.0, 35.0, -118.0, -114.0),
('Northern California', 35.0, 42.0, -124.0, -118.0),
('Alaska', 54.0, 72.0, -170.0, -130.0),
('Nevada', 35.0, 42.0, -120.0, -114.0),
('Japan', 30.0, 45.0, 129.0, 146.0),
('Chile', -56.0, -17.0, -75.0, -66.0),
('Idaho', 42.0, 49.0, -117.0, -111.0),
('Montana', 44.0, 49.0, -116.0, -104.0),
('Oregon', 42.0, 46.5, -124.5, -116.5),
('New Zealand', -47.0, -34.0, 166.0, 179.0);
