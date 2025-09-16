#!/bin/bash
total_fail=$(kube-bench run --targets master --json | jq .[].total_fail)
if [[ "$total_fail" -ne 0 ]];
then
    echo "CIS Benchmark Failed. Master node failed: $total_fail tests"
    exit 1;
else
    echo "CIS Benchmark Passed for Master node"
fi;
