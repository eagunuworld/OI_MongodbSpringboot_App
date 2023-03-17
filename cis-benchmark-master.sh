#!/bin/bash
#cis-master.sh

total_fail=$(sudo kube-bench --version 1.26 --check 1.1.1,1.1.16,1.2.12 --json | jq '.Totals.total_fail')

if [[ "$total_fail" -ne 0 ]];
        then
                echo "CIS Benchmark Failed MASTER while testing for 1.1.1, 1.1.16 and 1.2.12"
                exit 1;
        else
                echo "CIS Benchmark Passed for MASTER - 1.1.1, 1.1.16 and 1.2.12"
fi;