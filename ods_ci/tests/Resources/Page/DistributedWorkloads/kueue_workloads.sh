#!/bin/bash

local_queue_name=$1
namespace=$2
cpu_requested=$3
memory_requested=$4
job_name=$5

echo "Submitting kueue batch workloads"

cat <<EOF | kubectl apply --server-side -f -
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: $job_name
      namespace: $namespace
      labels:
        kueue.x-k8s.io/queue-name: $local_queue_name
    spec:
      suspend: true
      template:
        spec:
          containers:
          - name: test-job
            image: gcr.io/k8s-staging-perf-tests/watch-list:latest
            args: [40s"]
            resources:
              requests:
                cpu: $cpu_requested
                memory: ${memory_requested}Mi
          restartPolicy: Never
EOF
echo "kueue Job submitted successfully"
