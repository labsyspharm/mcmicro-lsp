#!/bin/bash
#SBATCH -p priority
#SBATCH -J mcmicro
#SBATCH -t 10-00:00
#SBATCH --mem=2G
#SBATCH --mail-type=END

# Verify that the user-specified directory is indeed an mcmicro project.
in="${1:-$(pwd)}"
if [ ! -e "$in/markers.csv" ]; then
  echo "ERROR: $0: Input directory '$in' doesn't look like an mcmicro 1.0 project directory (markers.csv was not found there)" >&2
  exit 1;
fi

# Load the java module which is required for nextflow.
module purge
module load java

# Limit nextflow memory to 1 GB.
export NXF_JVM_ARGS=-Xmx1g
# Run the latest version of nextflow that mcmicro 1.0 is compatible with.
export NXF_VER=25.10.7
# Set the workdir to a standard location in the user's scratch directory.
export NXF_WORK=/n/scratch/users/"${USER:0:1}/$USER"/nextflow-work

# Run the pipeline
echo "Launching mcmicro in $in"
echo
cd "$in"
nextflow run labsyspharm/mcmicro -profile O2LSP --in .

# Make a copy of qc logs and nextflow reports for future planning.
if [ -e qc/provenance ] || compgen -G 'pipeline_info/*' > /dev/null; then
  dest="/n/groups/lsp/mcmicro/reports/$USER-$(date -Iseconds)"
  mkdir -p "$dest"
  cp -r qc/provenance pipeline_info/* "$dest" 2>/dev/null
  echo "Copied provenance and pipeline reports to $dest"
fi
