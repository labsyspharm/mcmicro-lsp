#!/bin/bash

set -euo pipefail
shopt -s nullglob

usage=$(cat <<EOF
Usage: $(basename "$0") [-u] [-s] SAMPLE_DIRECTORY

  -u    Set this when using unmicst --scalingFactor 0.5
  -s    Set this when using s3segmenter-large version
EOF
)

sample_path=""
unmicst_scale=50
unmicst_offset=3
s3seg_scale=90
s3seg_offset=3

while getopts "ush" opt; do
    case "$opt" in
	u)
	    unmicst_scale=30
	    ;;
	s)
	    s3seg_scale=8
	    s3seg_offset=13
	    ;;
	h)
	    echo "$usage"
            exit 1
    esac
done
shift "$(($OPTIND -1))"
if [ $# -ne 1 ]; then
    echo "$usage"
    exit 1
fi
sample_path="$1"

if [ ! -d "$sample_path" -o ! -d "$sample_path/raw" ]; then
    echo "Not an mcmicro sample directory or raw images not present"
    exit 1
fi
raw_paths=("$sample_path"/raw/*.rcpnl)
if [ ${#raw_paths[@]} -eq 0 ]; then
    echo "Raw directory is empty"
    exit 1
fi
raw_path="${raw_paths[0]}"

channel_gpx=$(
    stat -c %s "$raw_path" \
    | awk '{ print $1 / 2 / 4 / 1000000000 }'
)
unmicst_gb=$(awk "{ print int($channel_gpx * $unmicst_scale + $unmicst_offset) }" <<< '')
s3seg_gb=$(awk "{ print int($channel_gpx * $s3seg_scale + $s3seg_offset) }" <<< '')

cat <<EOF
process {
  withName:worker {
    memory = '${unmicst_gb}G'
  }
  withName:s3seg {
    memory = '${s3seg_gb}G'
  }
}
EOF
