#!/bin/bash

set -euo pipefail
shopt -s nullglob

if [ $# -eq 0 ]; then
    cat <<EOF
Usage: $(basename "$0") SAMPLE_DIRECTORY
EOF
    exit 1
fi
sample_path="$1"

if [ -z "$sample_path" -o ! -d "$sample_path" -o ! -d "$sample_path/registration" ]; then
    echo "Not an mcmicro sample directory or registration output not present"
    exit 1
fi
tiff_paths=("$sample_path"/registration/*.ome.tif)
if [ ${#tiff_paths[@]} -eq 0 ]; then
    echo "Registration directory is empty"
    exit 1
elif [ ${#tiff_paths[@]} -gt 1 ]; then
    echo "Can't handle multiple registration images"
    exit 1
fi
tiff_path=${tiff_paths[0]}

memory_gb=$(
    tiffinfo -0 "$tiff_path" \
    | awk '/Image Width/ { print int($3 * $6 / 1000000000 * 50 + 3) }'
)

cat <<EOF
process {
  withName:worker {
    cpus   = 4
    time   = '12h'
    memory = '${memory_gb}G'
  }
}
EOF
