# PostgreSQL 17 JSON_TABLE() Demo

This repository demonstrates the new JSON_TABLE() function coming in PostgreSQL 17. JSON_TABLE() lets you query JSON data using standard SQL syntax - treating JSON documents as if they were relational tables.

## What is JSON_TABLE()?

JSON_TABLE() is a powerful new function that transforms JSON data into a relational format on the fly. It allows you to:

- Map JSON paths to SQL columns
- Automatically extract and type-cast values
- Query nested arrays and objects with familiar SQL syntax
- Join JSON data with regular tables

## Project Setup

This project uses Docker to run a PostgreSQL 17 development build with sample data for testing JSON_TABLE().

### Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/)
- [Docker Compose](https://docs.docker.com/compose/install/) (usually included with Docker Desktop)

### Files

- `docker-compose.yml` - Docker configuration for PostgreSQL 17
- `init.sql` - SQL script for creating tables and sample data
- `rebuild.sh` - Convenience script to rebuild and restart the container

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/sjksingh/pg17-json-table.git
cd pg17-json-table
```

### 2. Start the PostgreSQL container

```bash
# Make the rebuild script executable
chmod +x rebuild.sh

# Start the container
./rebuild.sh
```

### 3. Connect to the database

```bash
# Connect to the PostgreSQL container
docker exec -it pg17-json container psql -U postgres
```

Once connected, you're ready to run the example queries!

## Example Queries

### Basic JSON_TABLE() Query

Transform a JSON array into rows:

```sql
SELECT
    title,
    place,
    mag,
    ts,
    lat,
    lon
FROM earthquakes,
LATERAL JSON_TABLE(
    content,
    '$.features[*]'
    COLUMNS (
        title TEXT PATH '$.properties.title',
        place TEXT PATH '$.properties.place',
        mag REAL PATH '$.properties.mag',
        ts TEXT PATH '$.properties.time',
        lat REAL PATH '$.properties.location.lat',
        lon REAL PATH '$.properties.location.lon'
    )
) AS jt;
```

### Joining JSON with a Regular Table

```sql
SELECT
    jt.title,
    jt.place,
    jt.mag,
    jt.lat,
    jt.lon,
    r.region_name
FROM earthquakes
JOIN LATERAL JSON_TABLE(
    content,
    '$.features[*]'
    COLUMNS (
        title TEXT PATH '$.properties.title',
        place TEXT PATH '$.properties.place',
        mag REAL PATH '$.properties.mag',
        lat REAL PATH '$.properties.location.lat',
        lon REAL PATH '$.properties.location.lon'
    )
) AS jt ON true
JOIN regions r
  ON jt.lat BETWEEN r.lat_min AND r.lat_max
 AND jt.lon BETWEEN r.lon_min AND r.lon_max
ORDER BY r.region_name;
```

### Handling Missing Data

```sql
SELECT
    title,
    mag,
    COALESCE(depth, 0) AS depth_with_default,
    felt
FROM earthquakes,
LATERAL JSON_TABLE(
    content,
    '$.features[*]'
    COLUMNS (
        title TEXT PATH '$.properties.title',
        mag REAL PATH '$.properties.mag',
        depth REAL PATH '$.properties.depth',
        felt INT PATH '$.properties.felt'
    )
) AS jt;
```

### Compare with Pre-PostgreSQL 17 Method

```sql
-- The old way: Multiple lateral joins and explicit path extraction
SELECT 
    props->>'title' AS title,
    (props->>'mag')::REAL AS mag,
    (props->'location'->>'lat')::REAL AS lat,
    (props->'location'->>'lon')::REAL AS lon
FROM earthquakes,
LATERAL jsonb_array_elements(content->'features') AS features(feature),
LATERAL (SELECT feature->'properties') AS props(props);
```

## Step-by-Step Tutorial

### 1. Start PostgreSQL 17 Container
```bash
./rebuild.sh
```

### 2. Connect to PostgreSQL
```bash
docker exec -it pg17-json psql -U postgres
```

### 3. Explore the Data

Let's first look at the sample data structure:
```sql
-- See the raw JSON structure
SELECT id, content FROM earthquakes;

-- Check the regions table
SELECT * FROM regions;
```

### 4. Run the Examples

Try each of the example queries from the "Example Queries" section above.

### 5. Modify and Experiment

Create your own JSON_TABLE queries:
- Try different JSON paths
- Map different fields
- Add WHERE clauses
- Join with other tables

## Additional Resources

- [Full article on Medium](https://medium.com/@your-username/a-big-step-for-json-in-postgres-json-table-in-postgresql-17)
- [PostgreSQL JSON Functions Documentation](https://www.postgresql.org/docs/current/functions-json.html)
- [PostgreSQL 17 Development](https://www.postgresql.org/developer/roadmap/)

## Notes

- PostgreSQL 17 is currently in development (as of April 2025)
- The exact syntax and behavior of JSON_TABLE() may change before final release
- This demo uses a development version of PostgreSQL 17
