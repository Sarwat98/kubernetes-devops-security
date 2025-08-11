#!/bin/bash
# CIS Kubelet Benchmark Check (4.2.1, 4.2.2)

# Run kube-bench and parse JSON output for failures
total_fail=$(kube-bench run --targets node --version 1.15 --check 4.2.1,4.2.2 --json | jq -r '.Totals.total_fail')

if [[ "$total_fail" -ne 0 ]]; then
    echo "CIS Benchmark Failed Kubelet for checks 4.2.1, 4.2.2 (Failures: $total_fail)"
    exit 1
else
    echo "CIS Benchmark Passed Kubelet for 4.2.1, 4.2.2"
    exit 0
fi