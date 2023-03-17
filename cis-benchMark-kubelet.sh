#!/bin/bash
#cis-kubelet.sh

total_fail=$(sudo kube-bench --version 1.26 --check 4.1.4,4.2.5,4.2.13 --json | jq '.Totals.total_fail')

if [[ "$total_fail" -ne 0 ]];
        then
                echo "CIS Benchmark Failed Kubelet while testing for 4.1.4, 4.2.5 and 4.2.13"
                exit 1;
        else
                echo "CIS Benchmark Passed Kubelet for 4.1.4, 4.2.5 and 4.2.13"
fi;