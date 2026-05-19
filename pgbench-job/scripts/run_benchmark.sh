#!/bin/bash
set -e

echo "Starting PostgreSQL benchmarking session..."

# Run preparation
echo "Preparing pgbench database..."
/scripts/prepare_pgbench.sh

# Run benchmark tests
echo "Running pgbench tests..."
/scripts/run_pgbench_tests.sh

echo "Benchmark completed successfully!"
