#!/bin/bash
set -e

DB_NAME="${PGDATABASE}"
RESULTS_DIR="/results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULTS_DIR"

echo "=================================================="
echo "PostgreSQL Benchmark Tests"
echo "Started at: $(date)"
echo "=================================================="

run_test() {
    local test_name=$1
    local clients=$2
    local threads=$3
    local duration=$4
    local additional_opts=$5

    echo ""
    echo "### Running test: $test_name ###"
    echo "Clients: $clients, Threads: $threads, Duration: ${duration}s"

    local output_file="${RESULTS_DIR}/${TIMESTAMP}_${test_name}.log"

    pgbench \
        -c "$clients" \
        -j "$threads" \
        -T "$duration" \
        -P 5 \
        --progress-timestamp \
        $additional_opts \
        "$DB_NAME" | tee "$output_file"

    echo "Results saved to: $output_file"
}

# Checkpoint before starting
echo "Running checkpoint..."
psql -c "CHECKPOINT;"
sleep 5

# Test 1: Read-only test
echo ""
echo "=== Test 1: Read-Only Workload ==="
run_test "readonly" {{ .Values.benchmark.tests.readonly.clients }} {{ .Values.benchmark.tests.readonly.threads }} {{ .Values.benchmark.testDuration }} "-S"
sleep 10

# Test 2: Simple write test
echo ""
echo "=== Test 2: Simple Write Workload (TPC-B) ==="
run_test "simple_write" {{ .Values.benchmark.tests.simpleWrite.clients }} {{ .Values.benchmark.tests.simpleWrite.threads }} {{ .Values.benchmark.testDuration }} ""
sleep 10

# Test 3: Read-write test
echo ""
echo "=== Test 3: Read-Write Mixed Workload ==="
run_test "read_write" {{ .Values.benchmark.tests.readWrite.clients }} {{ .Values.benchmark.tests.readWrite.threads }} {{ .Values.benchmark.testDuration }} "-N"
sleep 10

# Test 4: Low concurrency
echo ""
echo "=== Test 4: Low Concurrency ==="
run_test "low_concurrency" {{ .Values.benchmark.tests.lowConcurrency.clients }} {{ .Values.benchmark.tests.lowConcurrency.threads }} {{ .Values.benchmark.testDuration }} ""
sleep 10

# Test 5: Medium concurrency
echo ""
echo "=== Test 5: Medium Concurrency ==="
run_test "medium_concurrency" {{ .Values.benchmark.tests.mediumConcurrency.clients }} {{ .Values.benchmark.tests.mediumConcurrency.threads }} {{ .Values.benchmark.testDuration }} ""
sleep 10

# Test 6: High concurrency
echo ""
echo "=== Test 6: High Concurrency ==="
run_test "high_concurrency" {{ .Values.benchmark.tests.highConcurrency.clients }} {{ .Values.benchmark.tests.highConcurrency.threads }} {{ .Values.benchmark.testDuration }} ""
sleep 10

# Test 7: Very high concurrency
echo ""
echo "=== Test 7: Very High Concurrency ==="
run_test "very_high_concurrency" {{ .Values.benchmark.tests.veryHighConcurrency.clients }} {{ .Values.benchmark.tests.veryHighConcurrency.threads }} {{ .Values.benchmark.testDuration }} ""
sleep 10

# Test 8: Prepared statements
echo ""
echo "=== Test 8: Prepared Statements ==="
run_test "prepared_statements" 8 2 {{ .Values.benchmark.testDuration }} "-M prepared"
sleep 10

# Test 9: Extended protocol
echo ""
echo "=== Test 9: Extended Protocol ==="
run_test "extended_protocol" 8 2 {{ .Values.benchmark.testDuration }} "-M extended"

# Generate summary report
echo ""
echo "=================================================="
echo "Generating summary report..."
echo "=================================================="

SUMMARY_FILE="${RESULTS_DIR}/${TIMESTAMP}_summary.txt"

cat > "$SUMMARY_FILE" << EOF
PostgreSQL Benchmark Summary
========================================
Date: $(date)
Hostname: $(hostname)
PostgreSQL Version: $(psql -t -c "SELECT version();")

Database Size: $(psql -t -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));")

Test Results Summary:
========================================

EOF

# Extract TPS from each test
for log_file in ${RESULTS_DIR}/${TIMESTAMP}_*.log; do
    if [ -f "$log_file" ]; then
        test_name=$(basename "$log_file" .log | sed "s/${TIMESTAMP}_//")
        tps=$(grep "^tps = " "$log_file" | tail -1 || echo "N/A")
        latency=$(grep "^latency average = " "$log_file" | tail -1 || echo "N/A")

        echo "Test: $test_name" >> "$SUMMARY_FILE"
        echo "  $tps" >> "$SUMMARY_FILE"
        echo "  $latency" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi
done

cat "$SUMMARY_FILE"

echo ""
echo "=================================================="
echo "All benchmarks completed!"
echo "Results directory: $RESULTS_DIR"
echo "Summary file: $SUMMARY_FILE"
echo "=================================================="
