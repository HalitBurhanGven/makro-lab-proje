#!/bin/sh
set -eu

export MAKRO_LAB_DOCUMENT_NAME=gorev-deneyi-acilista-v4.ods
export MAKRO_LAB_EXPECTED_HASH_FILE=/opt/makro-lab/gelen/gorev-deneyi-acilista-v4.sha256
export MAKRO_LAB_EXPERIMENT_PREFIX=ROOT-GORUNUR-GOREV-V4
export MAKRO_LAB_USER_EVIDENCE_SUFFIX=gorev-makbuzu
export MAKRO_LAB_ROOT_EVIDENCE_SUFFIX=gorev-makbuzu

exec /home/kali/makro-lab-proje/scripts/run_root_visible_experiment.sh
