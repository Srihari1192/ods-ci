#!/bin/bash

name=${name:-cluster-queue-mnist}
flavour=${flavour:-default-flavor-mnist}
local_queue_name=${local_queue_name:-local-queue-mnist}
namespace=$1
cpu_shared_quota=$2
memory_shared_quota=$3


echo "Applying Cluster Queue"

cat <<EOF | kubectl apply --server-side -f -
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: ClusterQueue
    metadata:
        name: $name
    spec:
      namespaceSelector: {}
      resourceGroups:
      - coveredResources: ["cpu", "memory", "pods", "nvidia.com/gpu"]
        flavors:
        - name: "default-flavor"
          resources:
          - name: "cpu"
            nominalQuota: $cpu_shared_quota
          - name: "memory"
            nominalQuota: ${memory_shared_quota}Gi
          - name: "pods"
            nominalQuota: 5
          - name: "nvidia.com/gpu"
            nominalQuota: 0
EOF
echo "Cluster Queue $name applied!"

echo "Applying Resource Flavour"
cat <<EOF | kubectl apply --server-side -f -
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: ResourceFlavor
    metadata:
        name: $flavour
EOF
echo "Resource Flavour $flavour applied!"

echo "Applying local queue"

cat <<EOF | kubectl apply --server-side -f -
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: LocalQueue
    metadata:
        namespace: $namespace
        name: $local_queue_name
        annotations:
          "kueue.x-k8s.io/default-queue": "true"
    spec:
      clusterQueue: $name
EOF
echo "Local Queue $local_queue_name applied!"
