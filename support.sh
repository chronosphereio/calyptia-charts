#!/bin/bash

# Script intended to capture any relevant logs and support information for on-premise deployment.
OUTPUT_DIR=${OUTPUT_DIR:-$(mktemp -d)}
TAR_NAME=${TAR_NAME:-/tmp/calyptia-support-$HOSTNAME-$(date -u +"%Y-%m-%dT%H-%M-%SZ").tgz}

echo "Running support script: $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"

if ! command -v kubectl &> /dev/null; then
    echo "ERROR: Missing kubectl"
    exit 1
fi

echo "Output stored here: $OUTPUT_DIR"

\kubectl get nodes -o yaml > "$OUTPUT_DIR"/kubectl-nodes.yaml
\kubectl get pods --all-namespaces -o yaml > "$OUTPUT_DIR"/kubectl-all-pods.yaml
\kubectl describe all --all-namespaces > "$OUTPUT_DIR"/kubectl-all.log

mkdir -p "$OUTPUT_DIR"/cluster
\kubectl cluster-info dump --all-namespaces -o yaml --output-directory="$OUTPUT_DIR"/cluster

# Grab stuff not returned by `get all`
for namespace in $(\kubectl get namespaces --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
do
    # Get YAML for everything in the namespace
    for resource_type in $(\kubectl api-resources --namespaced --verbs=list -o name | tr "\n" " ");
    do
        mkdir -p "${OUTPUT_DIR}/${namespace}"
        \kubectl get -n "$namespace" "$resource_type" --show-kind --ignore-not-found -o yaml > "${OUTPUT_DIR}/${namespace}"/"$resource_type".yaml
    done
done

# Grab all images used in the cluster: https://kubernetes.io/docs/tasks/access-application-cluster/list-all-running-container-images/
\kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" |\
    tr -s '[:space:]' '\n' |\
    sort |\
    uniq -c &> "$OUTPUT_DIR"/kubectl-all-images.log

# Finally grab extra logs for failing pods
for namespace in $(\kubectl get namespaces --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
do
    for pod in $(\kubectl get pods --field-selector=status.phase!=Running,status.phase!=Succeeded --namespace "$namespace" --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
    do
        pod_output_dir="${OUTPUT_DIR}/failing/${namespace}"/"${pod}"
        mkdir -p "$pod_output_dir"
        # Dump pod spec
        \kubectl describe --namespace "$namespace" pod "$pod" > "$pod_output_dir"/spec.yaml
        # Get previous logs
        \kubectl logs --namespace "$namespace" --previous "$pod" &> "$pod_output_dir"/previous.log
        # Get current logs just in case there is a race
        \kubectl logs --namespace "$namespace" "$pod" &> "$pod_output_dir"/current.log
    done
done

# Create a tarball for simple upload
echo "Creating tarball: $TAR_NAME"
tar -czf "$TAR_NAME" -C "$OUTPUT_DIR" .
chmod a+r "$TAR_NAME"

echo "Support script complete: $TAR_NAME"
echo "Please verify all content is acceptable to share - including secrets - and remove anything sensitive."
