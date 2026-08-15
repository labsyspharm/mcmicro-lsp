#!/bin/bash
#SBATCH -p priority
#SBATCH --mem 16G
#SBATCH -t 0-12
#SBATCH -J pull-container
#SBATCH -o /n/groups/lsp/mcmicro/singularity/slurm-pull-container-%j.o

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

# Set apptainer tmpdir to avoid using the default of ~/.apptainer (which would
# blow up the user's home dir quota).
export APPTAINER_TMPDIR=$(mktemp -d -p /n/groups/lsp/mcmicro/singularity/ pull-tmp.XXXXXXXXXX)
echo Setting APPTAINER_TMPDIR=$APPTAINER_TMPDIR

cmd="apptainer pull --disable-cache $out_path $url"
sg 'hits lsp-analysis' "$cmd"

# apptainer should have already cleaned up everything inside this dir.
rmdir $APPTAINER_TMPDIR
