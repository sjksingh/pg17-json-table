# PostgreSQL 17 JSON_TABLE Demo

This project demonstrates the new `JSON_TABLE` function in PostgreSQL 17 using Docker.

## Prerequisites
- Docker installed

## How to Run

1. Clone or unzip this project.
2. Open a terminal and navigate to the project directory.
3. Run:

```bash
docker-compose up -d
docker exec -it pg17-json psql -U postgres
```

4. Inside the psql shell, initialize the database:

```sql
\i /docker-entrypoint-initdb.d/init.sql
```

5. Run sample queries:

Expand JSON into relational format:

```sql
SELECT title, place, mag, ts, lat, lon
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

Join earthquakes to regions:

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

## Notes
- Uses official `postgres:17` image.
