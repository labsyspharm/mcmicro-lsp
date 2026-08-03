#!/bin/bash
#SBATCH -J mccellpose
#SBATCH -p gpu_quad
#SBATCH -t 0-8
#SBATCH -c 2
#SBATCH --mem=5g
#SBATCH --gres=gpu:1

in_path=$(realpath -e $1)
in_dir=$(dirname $in_path)
workdir=$(mktemp -d -p $in_dir)
fname=$(basename $in_path)
sample_id=${fname%.ome.tif}

echo "Working directory: $workdir"

apptainer exec \
  --no-home \
  --pid \
  -B "$workdir" \
  --nv \
  --env CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES" \
  /n/groups/lsp/mcmicro/singularity/docker.io-labsyspharm-mccellpose-1.0.3.img \
  /bin/bash \
  -c "cd $workdir; mccellpose -i ${in_path} -o ${in_dir}/${sample_id}-cellpose-cell.ome.tif --output-nucleus ${in_dir}/${sample_id}-cellpose-nucleus.ome.tif -c 1 --expand-size 2 --use-gpu --jobs 2"

rm -r $workdir
echo "Removed working directory"
