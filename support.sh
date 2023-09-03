#!/bin/bash
set -eu

# Script intended to capture any relevant logs and support information for on-premise deployment.
OUTPUT_DIR=${OUTPUT_DIR:-$(mktemp -d)}
TAR_NAME=${TAR_NAME:-/tmp/calyptia-support-$HOSTNAME-$(date -u +"%Y-%m-%dT%H-%M-%SZ").tgz}

echo "Running support script: $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"

if ! command -v kubectl &> /dev/null; then
    echo "ERROR: Missing kubectl"
    exit 1
fi

echo "Output stored here: $OUTPUT_DIR"

kubectl get nodes -o yaml > "$OUTPUT_DIR"/kubectl-nodes.yaml
kubectl get pods --all-namespaces -o yaml > "$OUTPUT_DIR"/kubectl-all-pods.yaml
kubectl describe all --all-namespaces > "$OUTPUT_DIR"/kubectl-all.log

mkdir -p "$OUTPUT_DIR"/cluster
kubectl cluster-info dump --all-namespaces -o yaml --output-directory="$OUTPUT_DIR"/cluster

# Grab stuff not returned by `get all`
for namespace in $(kubectl get namespaces --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
do
    # Get YAML for everything in the namespace
    for resource_type in $(kubectl api-resources --namespaced --verbs=list -o name | tr "\n" " ");
    do
        mkdir -p "${OUTPUT_DIR}/${namespace}"
        kubectl get -n "$namespace" "$resource_type" --show-kind --ignore-not-found -o yaml > "${OUTPUT_DIR}/${namespace}"/"$resource_type".yaml
    done
done

# Grab all images used in the cluster: https://kubernetes.io/docs/tasks/access-application-cluster/list-all-running-container-images/
kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" |\
    tr -s '[:space:]' '\n' |\
    sort |\
    uniq -c &> "$OUTPUT_DIR"/kubectl-all-images.log

# Create a tarball for simple upload
echo "Creating tarball: $TAR_NAME"
tar -czf "$TAR_NAME" -C "$OUTPUT_DIR" .
chmod a+r "$TAR_NAME"

echo "Support script complete: $TAR_NAME"
