#!/bin/bash

TASK="/home/Bo.Huang/Projects/AeroReanl/scripts/HPSS/toHPSS/BakCycles/job_bak_cycling_n2h.sh"
EXPS="
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007
"
FIELDS="
dr-data
dr-data-backup
"

for EXP in ${EXPS}; do
for FIELD in ${FIELDS}; do
echo "Running N2H-${EXP}-${FIELD}"
${TASK} ${EXP} ${FIELD}
done
done
