SELECT
    n.nspname AS schema_name,
    c.relname AS object_name,
    CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'v' THEN 'view'
        WHEN 'm' THEN 'materialized view'
        WHEN 'i' THEN 'index'
        WHEN 'S' THEN 'sequence'
        WHEN 't' THEN 'toast table'
        WHEN 'f' THEN 'foreign table'
        ELSE 'other'
    END AS object_type
FROM
    pg_class c
JOIN
    pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname NOT IN ('pg_catalog', 'information_schema') -- Exclude system schemas
    AND n.nspname !~ '^pg_toast' -- Exclude TOAST objects
    AND c.relkind IN ('r', 'v', 'm', 'S', 't', 'f') -- Include only specific object types
ORDER BY
    schema_name, object_type, object_name;
