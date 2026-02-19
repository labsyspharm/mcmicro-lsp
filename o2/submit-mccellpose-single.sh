#!/bin/bash
#SBATCH -J mccellpose
#SBATCH -p gpu_quad
#SBATCH -t 0-8
#SBATCH -c 2
#SBATCH --mem=5g
#SBATCH --gres=gpu:1

SAMPLE_ID="$1"
WORKDIR="$PWD"

apptainer exec \
  --no-home \
  --pid \
  -B "$WORKDIR" \
  --nv \
  --env CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES" \
  /n/groups/lsp/mcmicro/singularity/docker.io-labsyspharm-mccellpose-1.0.3.img \
  /bin/bash \
  -c "cd $WORKDIR; mccellpose -i $SAMPLE_ID.ome.tif -o $SAMPLE_ID-cellpose-cell.ome.tif --output-nucleus $SAMPLE_ID-cellpose-nucleus.ome.tif -c 1 --expand-size 2 --use-gpu --jobs 2"
