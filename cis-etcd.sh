#!/bin/bash
# CIS etcd Benchmark Check (2.2)

# Run kube-bench for etcd and parse JSON output
total_fail=$(kube-bench run --targets etcd --version 1.15 --check 2.2 --json | jq -r '.Totals.total_fail')

if [[ "$total_fail" -ne 0 ]]; then
    echo "CIS Benchmark Failed ETCD for check 2.2 (Failures: $total_fail)"
    exit 1
else
    echo "CIS Benchmark Passed ETCD for 2.2"
    exit 0
fi