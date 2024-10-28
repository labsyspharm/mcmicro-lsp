#!/bin/bash

set -euo pipefail
shopt -s nullglob

scriptname=$(basename "$0")

#######################################
# Emit an error message that will be readable from the command line, but also
# produces the same message as an exception in Nextflow if stdin is redirected
# into a nextflow config file.
# Arguments:
# 1: Error message
#######################################
error ()
{
    msg="$1"
    echo "$scriptname: $msg" >&2
    # If stdout is not a tty (as when redirecting to a file), emit a valid
    # Nextflow config that displays an error.
    test -t 1 || echo "process.memory = { throw new nextflow.exception.ConfigParseException('There was an error running $scriptname: $msg') }"
    exit 1
}

usage=$(cat <<EOF
Usage: $scriptname [-u] [-s] SAMPLE_DIRECTORY

Generates an mcmicro configuration file with resource limits for
stitching and segmentation. Use this script if you have not yet run
registration and only have raw .rcpnl or .czi files. Otherwise see
config_post_reg.sh .

  -u    Set this when using unmicst --scalingFactor 0.5
  -s    Set this when using s3segmenter-large version
EOF
)

sample_path=""
basic_scale=5
basic_offset=8
ashlar_scale=2
ashlar_offset=2.5
unmicst_scale=50
unmicst_offset=3
s3seg_scale=90
s3seg_offset=3

while getopts ":ush" opt; do
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
            ;;
        *)
            error "Invalid option: -$OPTARG"
    esac
done
shift "$(($OPTIND -1))"
if [ $# -ne 1 ]; then
    echo "$usage" >&2
    echo >&2
    error "Please specify the path to an mcmicro sample directory"
fi
sample_path="$1"

if [ ! -d "$sample_path" -o ! -d "$sample_path/raw" ]; then
    error "Not an mcmicro sample directory or raw images not present"
fi
raw_paths=("$sample_path"/raw/*.{rcpnl,czi})
if [ ${#raw_paths[@]} -eq 0 ]; then
    error "Raw directory is empty"
fi

channel_gpx=$(
    stat -L -c %s "${raw_paths[@]}" \
    | sort -n \
    | tail -1 \
    | awk '{ print $1 / 2 / 4 / 1000000000 }'
)
basic_gb=$(awk "{ print int($channel_gpx * $basic_scale + $basic_offset + 1) }" <<< '')
ashlar_gb=$(awk "{ print int($channel_gpx * $ashlar_scale + $ashlar_offset + 1) }" <<< '')
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
  withName:illumination {
    cpus = 4
    memory = { ${basic_gb}.GB * (1 + (task.attempt - 1) / 2) }
  }
  withName:ashlar {
    memory = { ${ashlar_gb}.GB * (1 + (task.attempt - 1) / 2) }
  }
  withName:worker {
    memory = { ${unmicst_gb}.GB * (1 + (task.attempt - 1) / 2) }
  }
  withName:s3seg {
    memory = { ${s3seg_gb}.GB * (1 + (task.attempt - 1) / 2) }
  }
}
EOF
