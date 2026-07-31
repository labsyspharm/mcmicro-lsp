#!/bin/bash
#SBATCH -p priority
#SBATCH -J mcmicro
#SBATCH -t 10-00:00
#SBATCH --mem=2G
#SBATCH --mail-type=END

in="${1:-$(pwd)}"
if [ ! -e "$in/markers.csv" ]; then
  echo "ERROR: $0: Input directory '$in' doesn't look like an mcmicro 1.0 project directory (markers.csv was not found there)" >&2
  exit 1;
fi

module purge
module load java

export NXF_JVM_ARGS=-Xmx1g
export NXF_VER=25.10.7
export NXF_WORK=/n/scratch/users/"${USER:0:1}/$USER"/nextflow-work

echo "Launching mcmicro in $in"
echo
cd "$in"

nextflow run labsyspharm/mcmicro -profile O2LSP --in .
