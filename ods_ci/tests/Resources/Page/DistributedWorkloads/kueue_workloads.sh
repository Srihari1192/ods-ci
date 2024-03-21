#!/bin/bash

name=${name:-cluster-queue-mnist}
flavour=${flavour:-default-flavor-mnist}
local_queue_name=${local_queue_name:-local-queue-mnist}
namespace=$1
cpu_requested=$2
memory_requested=$3

echo "Submitting batch workloads"

cat <<EOF | kubectl apply --server-side -f -
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: sample-job-0
      namespace: $namespace
      labels:
        kueue.x-k8s.io/queue-name: $local_queue_name
      annotations:
        kueue.x-k8s.io/job-min-parallelism: "5"
    spec:
      parallelism: 6
      completions: 6
      suspend: true
      template:
        spec:
          containers:
          - name: dummy-job
            image: gcr.io/k8s-staging-perf-tests/sleep:v0.1.0
            args: ["30s"]
            resources:
              requests:
                cpu: $cpu_requested
                memory: ${memory_requested}Mi
          restartPolicy: Never
EOF
echo "Job submitted successfully"
