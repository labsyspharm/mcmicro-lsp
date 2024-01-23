#!/bin/bash

set -euo pipefail
shopt -s nullglob extglob

scriptname=$(basename "$0")

error ()
{
    # Emit an error message that will be readable from the command line, but
    # also produces the same message as an exception in Nextflow if the
    # generated config is used sight unseen.
    msg="$1"
    echo "ERROR: $msg" >&2
    cat <<EOF
process.memory = { throw new nextflow.exception.ConfigParseException('There was an error running $scriptname: $msg') }
EOF
    exit 1
}

usage=$(cat <<EOF
Usage: $scriptname [-u] [-s] SAMPLE_DIRECTORY

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
    echo "$usage" >&2
    # If stdout is not a tty (as when redirecting to a file), emit a valid
    # Nextflow config that displays an error.
    test -t 1 || echo "process.memory = { throw new nextflow.exception.ConfigParseException('There was an error running $scriptname: Invalid options') }"
    exit 1
fi
sample_path="$1"

if [ ! -d "$sample_path" -o ! -d "$sample_path/registration" ]; then
    error "Not an mcmicro sample directory or registration output not present"
fi
tiff_paths=("$sample_path"/registration/*.ome.@(tif|tiff))
if [ ${#tiff_paths[@]} -eq 0 ]; then
    error "Registration directory is empty"
elif [ ${#tiff_paths[@]} -gt 1 ]; then
    error "Can't handle multiple registration images"
fi
tiff_path=${tiff_paths[0]}

module purge
module load gcc tiff

channel_gpx=$(
    tiffinfo -0 "$tiff_path" \
    | awk '/Image Width/ { print $3 * $6 / 1000000000 }'
)
unmicst_gb=$(awk "{ print int($channel_gpx * $unmicst_scale + $unmicst_offset + 1) }" <<< '')
s3seg_gb=$(awk "{ print int($channel_gpx * $s3seg_scale + $s3seg_offset + 1) }" <<< '')

cat <<EOF
manifest {
  nextflowVersion = '!>=23.04.3'
}

process {
  cpus = 1
  maxRetries = 2
  errorStrategy = { task.exitStatus in 137..140 ? 'retry' : 'terminate' }
  withName:worker {
    memory = { ${unmicst_gb}.GB * (1 + (task.attempt - 1) / 2) }
  }
  withName:s3seg {
    memory = { ${s3seg_gb}.GB * (1 + (task.attempt - 1) / 2) }
  }
}
EOF
