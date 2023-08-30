#!/bin/bash

set -euo pipefail
shopt -s nullglob

usage=$(cat <<EOF
Usage: $(basename "$0") [-u] [-s] SAMPLE_DIRECTORY

Generates an mcmicro configuration file with resource limits for
stitching and segmentation. Use this script if you have not yet run
registration and only have raw .rcpnl files. Otherwise see config_post_reg.sh .

  -u    Set this when using unmicst --scalingFactor 0.5
  -s    Set this when using s3segmenter-large version
EOF
)

sample_path=""
ashlar_scale=2
ashlar_offset=2.5
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

channel_gpx=$(
    stat -L -c %s "${raw_paths[@]}" \
    | sort -n \
    | tail -1 \
    | awk '{ print $1 / 2 / 4 / 1000000000 }'
)
ashlar_gb=$(awk "{ print int($channel_gpx * $ashlar_scale + $ashlar_offset + 1) }" <<< '')
unmicst_gb=$(awk "{ print int($channel_gpx * $unmicst_scale + $unmicst_offset + 1) }" <<< '')
s3seg_gb=$(awk "{ print int($channel_gpx * $s3seg_scale + $s3seg_offset + 1) }" <<< '')

cat <<EOF
process {
  cpus 1
  errorStrategy { task.exitStatus == 125 ? 'retry' : 'terminate' }
  maxRetries 2
  withName:ashlar {
    memory { ${ashlar_gb}.GB * task.attempt }
  }
  withName:worker {
    memory { ${unmicst_gb}.GB * task.attempt }
  }
  withName:s3seg {
    memory { ${s3seg_gb}.GB * task.attempt }
  }
}
EOF
