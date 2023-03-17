#!/bin/bash
#cis-etcd.sh

total_fail=$(sudo kube-bench --version 1.26 --check 2.4,2.5,2.6 --json | jq '.Totals.total_fail')

if [[ "$total_fail" -ne 0 ]];
        then
                echo "CIS Benchmark Failed ETCD while testing for 2.4, 2.5 and 2.6."
                exit 1;
        else
                echo "CIS Benchmark Passed for ETCD - 2.4, 2.5 and 2.6."
fi;