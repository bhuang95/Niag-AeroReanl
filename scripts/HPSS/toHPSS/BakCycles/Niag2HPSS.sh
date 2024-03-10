#!/bin/bash

TASKDIR="/home/Bo.Huang/Projects/AeroReanl/scripts/HPSS/toHPSS/BakCycles"
TASKS="
job_bak_cycling_n2h_AeroDA202007_dr-data
job_bak_cycling_n2h_AeroDA202007_dr-data-backup
"
for TASK in ${TASKS}; do
echo "Run ${DIR}/${TASK}"
${TASKDIR}/${TASK}.sh
done
