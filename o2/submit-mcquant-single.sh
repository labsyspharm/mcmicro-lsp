#!/bin/bash
#SBATCH -J mcquant
#SBATCH -p short
#SBATCH -t 0-8
#SBATCH --mem=128g

in_path=$(realpath -e $1)
workdir=$(dirname $in_path)
fname=$(basename $in_path)
sample_id=${fname%.ome.tif}

apptainer exec \
  --no-home \
  --pid \
  -B "$workdir" \
  /n/groups/lsp/mcmicro/singularity/labsyspharm-quantification-1.6.0.img \
  /bin/bash \
  -c "cd $workdir; mcquant --image ${fname} --masks ${sample_id}-cellpose-{cell,nucleus}.ome.tif --channel_names markers.csv --output ."

cd ${workdir}
for c in cell nucleus; do
  mv ${sample_id}_${sample_id}-cellpose-${c}.csv ${sample_id}-cellpose-${c}.csv
done
