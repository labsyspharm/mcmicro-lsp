#!/bin/bash

set -euo pipefail

show_usage() {
    cat <<EOF
Usage: $(basename "$0") docker://organization/container:tag
EOF
}

if [ $# -ne 1 ]; then
    show_usage
    echo
    echo "Downloads a docker container into the mcmicro container cache directory"
    exit 1
fi

url="$1"
# Validate url format up front to simplify parsing later.
if [ -z $(echo "$url" | grep -P '^docker://[^/ ]+/[^/ ]+:[^ ]+$' || true) ]; then
    echo "Invalid dockerhub URI"
    show_usage
    exit 1
fi
org_cont_tag=${url:9}
org=${org_cont_tag/\/*/}
cont_tag=${org_cont_tag/*\//}
cont=${cont_tag/:*/}
tag=${cont_tag/*:/}
out_path=/n/groups/lsp/mcmicro/singularity/$org-$cont-$tag.img

echo "Container: $url"
echo "Destination: $out_path"

cmd="apptainer pull $out_path $url"
sg 'hits lsp-analysis' "$cmd"
