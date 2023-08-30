#!/bin/bash

set -euo pipefail
shopt -s nullglob

usage=$(cat <<EOF
Usage: $(basename "$0") [-u] [-s] SAMPLE_DIRECTORY

Generates an mcmicro configuration file with resource limits for
segmentation. Use this script if you have run registration and have a
stitched .ome.tif file. Otherwise see config_pre_reg.sh .

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

if [ ! -d "$sample_path" -o ! -d "$sample_path/registration" ]; then
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

module load gcc tiff

channel_gpx=$(
    tiffinfo -0 "$tiff_path" \
    | awk '/Image Width/ { print $3 * $6 / 1000000000 }'
)
unmicst_gb=$(awk "{ print int($channel_gpx * $unmicst_scale + $unmicst_offset + 1) }" <<< '')
s3seg_gb=$(awk "{ print int($channel_gpx * $s3seg_scale + $s3seg_offset + 1) }" <<< '')

cat <<EOF
process {
  cpus 1
  errorStrategy { task.exitStatus == 125 ? 'retry' : 'terminate' }
  maxRetries 2
  withName:worker {
    memory { ${unmicst_gb}.GB * task.attempt }
  }
  withName:s3seg {
    memory { ${s3seg_gb}.GB * task.attempt }
  }
}
EOF
