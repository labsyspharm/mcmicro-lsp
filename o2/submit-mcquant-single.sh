#!/bin/bash
#SBATCH -J mcquant
#SBATCH -p short
#SBATCH -t 0-8
#SBATCH --mem=128g

SAMPLE_ID="$1"
WORKDIR="$PWD"

apptainer exec \
  --no-home \
  --pid \
  -B "$WORKDIR" \
  /n/groups/lsp/mcmicro/singularity/labsyspharm-quantification-1.6.0.img \
  /bin/bash \
  -c "cd $WORKDIR; mcquant --image ${SAMPLE_ID}.ome.tif --masks ${SAMPLE_ID}-cellpose-{cell,nucleus}.ome.tif --channel_names markers.csv --output ."
