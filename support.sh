#!/bin/bash

# Script intended to capture any relevant logs and support information for on-premise deployment.
OUTPUT_DIR=${OUTPUT_DIR:-$(mktemp -d)}
TAR_NAME=${TAR_NAME:-/tmp/calyptia-support-$HOSTNAME-$(date -u +"%Y-%m-%dT%H-%M-%SZ").tgz}

# Set this to a token to use for working with the Calyptia configuration
CALYPTIA_CLOUD_TOKEN=${CALYPTIA_CLOUD_TOKEN:-}
# Set this to the location of the cloud-api endpoint to use
CALYPTIA_CLOUD_URL=${CALYPTIA_CLOUD_URL:-}

# Finds a random, unused port on the system and echos it.
# Returns 1 and echos -1 if it can't find one.
function find_unused_port() {
    local portnum
    while true; do
        portnum=$(shuf -i 1025-65535 -n 1)
        if ! lsof -Pi ":$portnum" -sTCP:LISTEN; then
            echo "$portnum"
            return 0
        fi
    done
    echo -1
    return 1
}

NAMESPACE_LIST=()
while getopts "n:" opt; do
  case $opt in
    n) NAMESPACE_LIST+=("$OPTARG");;
  esac
done
shift $((OPTIND-1))

if [ ${#NAMESPACE_LIST[@]} -eq 0 ]; then
  NAMESPACE_LIST+=("calyptia")
fi

NAMESPACE_LIST+=($(kubectl get ns -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep '^kube-'))
NAMESPACE_LIST+=("default")

NAMESPACE_LIST=($(printf "%s\n" "${NAMESPACE_LIST[@]}" | sort -u))
NAMESPACE_CS=$(IFS=, ; echo "${NAMESPACE_LIST[*]}")

echo "Running support script: $(date -u +"%Y-%m-%dT%H:%M:%SZ") $*"
echo "Using namespaces: ${NAMESPACE_LIST[*]}"

if ! command -v kubectl &> /dev/null; then
    echo "ERROR: Missing kubectl"
    exit 1
fi

echo "Output stored here (add extra information beforehand to be tarred up): $OUTPUT_DIR"
# Ensure we have the directory
mkdir -p "$OUTPUT_DIR"

\kubectl get nodes -o yaml > "$OUTPUT_DIR"/kubectl-nodes.yaml
\kubectl get -o yaml crd > "$OUTPUT_DIR"/kubectl-crds.yaml


\kubectl get pods --all-namespaces -o yaml > "$OUTPUT_DIR"/kubectl-all-pods.yaml
\kubectl describe all --all-namespaces > "$OUTPUT_DIR"/kubectl-all.log

mkdir -p "$OUTPUT_DIR"/cluster
\kubectl cluster-info dump --namespaces $NAMESPACE_CS -o yaml --output-directory="$OUTPUT_DIR"/cluster

# Grab stuff not returned by `get all`
for namespace in ${NAMESPACE_LIST[@]}
do
    # Get YAML for everything in the namespace, except secrets. If more resources need to be excluded, add them to the grep list.
    for resource_type in $(\kubectl api-resources --namespaced --verbs=list -o name | grep -Ewv "^(secrets)$" | tr "\n" " ");
    do
        mkdir -p "${OUTPUT_DIR}/namespaces/${namespace}"
        \kubectl get -n "$namespace" "$resource_type" --show-kind --ignore-not-found -o yaml > "${OUTPUT_DIR}/namespaces/${namespace}"/"$resource_type".yaml
    done

    # Get secrets in the namespace. All data values will be redacted.
    for secret in $(\kubectl get secrets -n "$namespace" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
    do
        \kubectl get secret "$secret" -n "$namespace" -o json | jq '.data |= with_entries(.value = "--REDACTED--")' >> "${OUTPUT_DIR}/namespaces/${namespace}"/secrets.json
    done

    # Attempt to discover token and url for cloud-api in cluster
    if [[ -z "$CALYPTIA_CLOUD_TOKEN" ]]; then
        if \kubectl get --namespace "$namespace" secret auth-secret &>/dev/null; then
            CALYPTIA_CLOUD_TOKEN=$(kubectl get --namespace "$namespace" secret auth-secret -o jsonpath='{.data.token}'| base64 --decode)
            export CALYPTIA_CLOUD_TOKEN
            if [[ -z "$CALYPTIA_CLOUD_TOKEN" ]]; then
                # Use the old approach
                CALYPTIA_CLOUD_TOKEN=$(kubectl get --namespace "$namespace" secret auth-secret -o jsonpath='{.data.ONPREM_CLOUD_API_PROJECT_TOKEN}'| base64 --decode)
                export CALYPTIA_CLOUD_TOKEN
            fi
            # Detain the token for comparison in the pod specs
            echo -n "$CALYPTIA_CLOUD_TOKEN" > "${OUTPUT_DIR}"/token.txt
        fi
    fi

    if [[ -z "$CALYPTIA_CLOUD_URL" ]]; then
        if \kubectl get --namespace "$namespace" svc -l 'app.kubernetes.io/component=cloud-api' | grep -qv "No resources found"; then
            if [[ $(\kubectl get --namespace "$namespace" svc -l 'app.kubernetes.io/component=cloud-api' -o=jsonpath='{.items..spec.type}') == 'LoadBalancer' ]]; then
                service_lb_ip=$(kubectl get -n "$namespace" svc -l 'app.kubernetes.io/component=cloud-api' -o=jsonpath='{.items..status.loadBalancer.ingress[0].ip}')
                if [[ -z "$service_lb_ip" ]]; then
                    service_lb_ip=$(kubectl get -n "$namespace" svc -l 'app.kubernetes.io/component=cloud-api' -o=jsonpath='{.items..status.loadBalancer.ingress[0].hostname}')
                fi
                service_lb_port=$(kubectl get -n "$namespace" svc -l 'app.kubernetes.io/component=cloud-api' -o=jsonpath='{.items..spec.ports[0].port}')

                CALYPTIA_CLOUD_URL="http://${service_lb_ip}:${service_lb_port}"
                export CALYPTIA_CLOUD_URL
            else
                # port-forwarding required
                local_port=$(find_unused_port)
                if [[ "$local_port" != '-1' ]]; then
                    \kubectl port-forward --namespace "$namespace" \
                        svc/"$(\kubectl get --namespace "$namespace" svc -l 'app.kubernetes.io/component=cloud-api' -o=jsonpath='{.items..metadata.name}')" \
                        "$local_port:5000" &
                    export PF_PID=$!
                    export CALYPTIA_CLOUD_URL="http://127.0.0.1:$local_port"
                fi
            fi
        fi
    fi
done

# Grab all images used in the cluster: https://kubernetes.io/docs/tasks/access-application-cluster/list-all-running-container-images/
\kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" |\
    tr -s '[:space:]' '\n' |\
    sort |\
    uniq -c &> "$OUTPUT_DIR"/kubectl-all-images.log

for namespace in $(\kubectl get namespaces --output=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
do
    # Finally grab extra logs for failing pods
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

# Attempt to dump some Calyptia configuration details using the URL and token provided
if command -v calyptia &> /dev/null && [[ -n "$CALYPTIA_CLOUD_URL" ]] && [[ -n "$CALYPTIA_CLOUD_TOKEN" ]]; then
    for core in $(calyptia --token "$CALYPTIA_CLOUD_TOKEN" --cloud-url "$CALYPTIA_CLOUD_URL" get core_instances -o json | jq -r '.[].id')
    do
        for pipeline in $(calyptia get pipelines "$CALYPTIA_CLOUD_TOKEN" --cloud-url "$CALYPTIA_CLOUD_URL" --core-instance "$core" -o json | jq -r '.[].id')
        do
            mkdir -p "$OUTPUT_DIR/instances/${core}/${pipeline}"
            \curl -H "Authorization: Bearer ${CALYPTIA_CLOUD_TOKEN}" -sSfL "${CALYPTIA_CLOUD_URL}/v1/pipelines/${pipeline}/metadata" &> "$OUTPUT_DIR/instances/${core}/${pipeline}"/metadata.json
        done
    done
else
    echo "Unable to extract any Calyptia instance configuration details, ensure Calyptia CLI is installed and CALYPTIA_CLOUD_URL/CALYPTIA_CLOUD_TOKEN are set."
fi

# Kill any port-forwarding without output
[[ -n "${PF_PID:-}" ]] && kill -9 "$PF_PID" && wait "$PF_PID" 2>/dev/null

# Grab any helm values directly
if command -v jq && command -v gunzip && command -v base64; then
    for helm_json in $(kubectl get secrets -A -l owner=helm -o json | jq -c .items[])
    do
        helm_name=$(echo "$helm_json" | jq '.metadata.name')
        mkdir -p "$OUTPUT_DIR/helm/$helm_name"
        # Extract the template and values used
        echo "$helm_json" | jq -r '.data.release' | base64 -d | base64 -d | gunzip -c - | jq -c '.' &> "$OUTPUT_DIR/helm/$helm_name"/all.json
        jq '.config' "$OUTPUT_DIR/helm/$helm_name"/all.json &> "$OUTPUT_DIR/helm/$helm_name"/values.json
        jq -r '.chart.templates[].data' "$OUTPUT_DIR/helm/$helm_name"/all.json | base64 -d &> "$OUTPUT_DIR/helm/$helm_name"/template.yaml
    done
else
    echo "Unable to extract helm values as missing jq, gunzip or base64 commands"
fi

# Grab any K3S logs for on-prem deployment
journalctl -q -u k3s &> "$OUTPUT_DIR"/k3s-service.log

# Check for systemctl and scrape systemctl units if available
if command -v systemctl &> /dev/null; then
    echo "Scraping systemctl units..."
    systemctl list-units --all --type=service --no-pager &> "$OUTPUT_DIR/systemctl-all-units.log"
    echo "Systemctl units scraped."
else
    echo "Systemctl not found, skipping systemctl units scrape."
fi

# Create a tarball for simple upload
echo "Creating tarball: $TAR_NAME"
tar -czf "$TAR_NAME" -C "$OUTPUT_DIR" .
chmod a+r "$TAR_NAME"

echo "Support script complete: $TAR_NAME"
echo "Please verify all content is acceptable to share - including secrets - and remove anything sensitive."
