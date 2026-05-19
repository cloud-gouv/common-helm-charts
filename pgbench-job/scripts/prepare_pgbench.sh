#!/bin/bash
set -e

echo "=================================================="
echo "PostgreSQL Benchmark Preparation"
echo "=================================================="

DB_NAME="${PGDATABASE}"
SCALE_FACTOR={{ .Values.benchmark.scaleFactor }}

echo "Dropping existing pgbench tables if they exist..."
psql -c "DROP TABLE IF EXISTS pgbench_accounts, pgbench_branches, pgbench_tellers, pgbench_history CASCADE;" || true

echo "Initializing pgbench with scale factor: $SCALE_FACTOR"
echo "This will create a database of approximately $(($SCALE_FACTOR * 15))MB"

pgbench -i -s "$SCALE_FACTOR" "$DB_NAME"

echo ""
echo "Running VACUUM ANALYZE to update statistics..."
psql -c "VACUUM ANALYZE;"

echo ""
echo "PostgreSQL version and settings:"
psql -c "SELECT version();"
psql -c "SHOW shared_buffers;"
psql -c "SHOW effective_cache_size;"
psql -c "SHOW max_connections;"

echo ""
echo "Preparation completed successfully!"
