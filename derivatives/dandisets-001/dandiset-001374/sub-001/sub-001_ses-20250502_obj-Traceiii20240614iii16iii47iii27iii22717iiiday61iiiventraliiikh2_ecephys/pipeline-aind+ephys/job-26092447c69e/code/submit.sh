#!/bin/bash
#SBATCH --job-name=AIND-Ephys-Pipeline
#SBATCH --output=/orcd/data/dandi/001/dandi-compute/processing/prepare-job-8vfuqrj4/001697/derivatives/dandisets-001/dandiset-001374/sub-001/sub-001_ses-20250502_obj-Traceiii20240614iii16iii47iii27iii22717iiiday61iiiventraliiikh2_ecephys/pipeline-aind+ephys/job-26092447c69e/logs/job-%j_slurm.log
#SBATCH --mem=1GB
#SBATCH --cpus-per-task 1
#SBATCH --partition=mit_normal
#SBATCH --time=12:00:00

NWB_FILE_PATH="/orcd/data/dandi/001/s3dandiarchive/blobs/1a1/f2d/1a1f2d76-cc84-489a-a458-f3f59f6c5958"
DATA_PATH="/orcd/data/dandi/001/s3dandiarchive/blobs/1a1/f2d"

RESULTS_PATH="/orcd/data/dandi/001/dandi-compute/processing/prepare-job-8vfuqrj4/001697/derivatives/dandisets-001/dandiset-001374/sub-001/sub-001_ses-20250502_obj-Traceiii20240614iii16iii47iii27iii22717iiiday61iiiventraliiikh2_ecephys/pipeline-aind+ephys/job-26092447c69e/intermediate"
WORKDIR="/orcd/data/dandi/001/dandi-compute/work"
NXF_APPTAINER_CACHEDIR="/orcd/data/dandi/001/dandi-compute/work/apptainer_cache"

source /etc/profile.d/modules.sh
module load miniforge
module load apptainer

conda activate /orcd/data/dandi/001/environments/name-nextflow_environment

# Ensure the correct version of AIND pipeline is used
git -C "/orcd/data/dandi/001/dandi-compute/aind-ephys-pipeline" checkout 1.3.3

# Need to ensure latest DANDI-CLI version is always used, otherwise upload of logs may not be possible at the end
pip install -U dandi

# Run nextflow from a unique per-job directory so each job gets its own
# isolated .nextflow/ (history + cache) and they don't fight over file locks.
RUNDIR="/orcd/data/dandi/001/dandi-compute/processing/prepare-job-8vfuqrj4/001697/derivatives/dandisets-001/dandiset-001374/sub-001/sub-001_ses-20250502_obj-Traceiii20240614iii16iii47iii27iii22717iiiday61iiiventraliiikh2_ecephys/pipeline-aind+ephys/job-26092447c69e/logs"
cd "$RUNDIR"

DATA_PATH="$DATA_PATH" RESULTS_PATH="$RESULTS_PATH" NXF_APPTAINER_CACHEDIR="$NXF_APPTAINER_CACHEDIR" nextflow \
    -C "/orcd/data/dandi/001/dandi-compute/processing/prepare-job-8vfuqrj4/001697/derivatives/dandisets-001/dandiset-001374/sub-001/sub-001_ses-20250502_obj-Traceiii20240614iii16iii47iii27iii22717iiiday61iiiventraliiikh2_ecephys/pipeline-aind+ephys/job-26092447c69e/code/name-mit+engaging_revision-2.config" \
    -log "/orcd/data/dandi/001/dandi-compute/processing/prepare-job-8vfuqrj4/001697/derivatives/dandisets-001/dandiset-001374/sub-001/sub-001_ses-20250502_obj-Traceiii20240614iii16iii47iii27iii22717iiiday61iiiventraliiikh2_ecephys/pipeline-aind+ephys/job-26092447c69e/logs/nextflow.log" \
    run "/orcd/data/dandi/001/dandi-compute/aind-ephys-pipeline/pipeline/main_multi_backend.nf" \
    -work-dir "$WORKDIR" \
    --params_file "/orcd/data/dandi/001/dandi-compute/processing/prepare-job-8vfuqrj4/001697/derivatives/dandisets-001/dandiset-001374/sub-001/sub-001_ses-20250502_obj-Traceiii20240614iii16iii47iii27iii22717iiiday61iiiventraliiikh2_ecephys/pipeline-aind+ephys/job-26092447c69e/code/name-original_version-1+2+4.json" \
    --job_dispatch_args "--nwb-files $NWB_FILE_PATH"

echo "=== Directory tree of \$RESULTS_PATH after nextflow run ==="
tree "$RESULTS_PATH" || find "$RESULTS_PATH" -print
echo "=== End of directory tree ==="

cd $RESULTS_PATH
mv nwb/ ../derivatives/
mv visualization_output.json visualization/
mv quality_control.json visualization/
find quality_control/ -type f -name "*.png" -exec mv -t visualization/ {} +
mv visualization/ ../derivatives/
mv postprocessed/ ../derivatives/
mv nextflow/* ../logs/
cd ..
rm -rf $RESULTS_PATH  # Clean up intermediate values

dandi upload --validation skip  # Dandiset is valid if ignoring NWBI issues from copied files (BIDS part is valid)
echo "prepare-job-8vfuqrj4" >> /orcd/data/dandi/001/dandi-compute/processing/done.txt
