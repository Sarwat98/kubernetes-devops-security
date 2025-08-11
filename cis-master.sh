#!/bin/bash
# CIS Kubernetes Master Benchmark Check (1.2.7, 1.2.8, 1.2.9)

# Run kube-bench for master components and parse JSON output
total_fail=$(kube-bench run --targets master --version 1.15 --check 1.2.7,1.2.8,1.2.9 --json | jq -r '.Totals.total_fail')

if [[ "$total_fail" -ne 0 ]]; then
    echo "CIS Benchmark Failed MASTER for checks 1.2.7, 1.2.8, 1.2.9 (Failures: $total_fail)"
    exit 1
else
    echo "CIS Benchmark Passed MASTER for 1.2.7, 1.2.8, 1.2.9"
    exit 0
fi