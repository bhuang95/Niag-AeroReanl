#!/bin/bash
#SBATCH -J cyc_n2h
#SBATCH -A niagara
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /collab1/data/Bo.Huang/dataTransfer/AeroReanl/ChgresGDAS/cyc_n2h.out
#SBATCH -e /collab1/data/Bo.Huang/dataTransfer/AeroReanl/ChgresGDAS/cyc_n2h.out

module load hpss

set -x

CYCINC=6
NDATE="/home/Bo.Huang/Projects/AeroReanl/bin/ndate"
CURDIR="/home/Bo.Huang/Projects/AeroReanl/scripts/HPSS/fromHPSS"

SCRIPTDIR="/home/Bo.Huang/Projects/AeroReanl/scripts/HPSS/toHPSS/BakCycles"
RECDIR=${SCRIPTDIR}/CYC_N2H_RECORD
TOPNIAG="/collab1/data/Bo.Huang/FromOrion/expRuns/AeroReanl/"
TOPHPSS="/BMC/fim/5year/MAPP_2018/bhuang/UFS-Aerosols-expRuns/UFS-Aerosols_RETcyc/AeroReanl/"

EXPS="
AeroReanl_EP4_AeroDA_YesSPEEnKF_YesSfcanl_v15_0dz0dp_41M_C96_202007
"
FIELDS="
dr-data
"
#dr-data-backup

NCP="/bin/cp -r"

[[ ! -d ${RECDIR} ]] && mkdir -p ${RECDIR}
for EXP in ${EXPS}; do
for FIELD in ${FIELDS};do
    EXPNIAG=${TOPNIAG}/${EXP}/${FIELD}/	
    EXPHPSS=${TOPHPSS}/${EXP}/${FIELD}/

    EXPNIAG_CYC=${EXPNIAG}/toHPSS/CYCLE.info
    CDATE=$(cat ${EXPNIAG_CYC})
    if [ ${CDATE} -gt 2020072418 ]; then
        exit 0
    fi
    EXPNIAG_TMP=${EXPNIAG}/toHPSS/tmp/${CDATE}
    EXPNIAG_TMP_STATUS=${EXPNIAG_TMP}/N2H.status
    if ( grep "${CDATE}: SUCCEEDED" ${EXPNIAG_TMP_STATUS} ); then
        echo "${EXP} at ${CDATE} is complete and wait to next cycle."
	exit 0
    elif ( grep "${CDATE}: ONGOING" ${EXPNIAG_TMP_STATUS} ); then
        echo "${EXP} at ${CDATE} is ongoing and wait."
	exit 0
    else
        EXPGLBUS_REC=${EXPNIAG}/${CDATE}/Globus_o2n_${CDATE}.record
	if ( grep SUCCESSFUL ${EXPGLBUS_REC} ); then
            cd ${EXPNIAG}/${CDATE}
	    EXPNIAG_FILES=$(ls *.tar)

	    [[ ! -d ${EXPNIAG_TMP} ]] && mkdir -p ${EXPNIAG_TMP}
	    cd ${EXPNIAG_TMP}
	    ${NCP} ${SCRIPTDIR}/sbatch_niag2hpss_cycle.sh ./
CY=${CDATE:0:4}
CM=${CDATE:4:2}
CD=${CDATE:6:2}
CH=${CDATE:8:2}
NEXTCYC=$(${NDATE} ${CYCINC} ${CDATE})
cat << EOF > config_niag2hpss_cycle
CDATE=${CDATE}
EXPNIAG_DIR=${EXPNIAG}/${CDATE}
EXPHPSS_DIR=${EXPHPSS}/${CY}/${CY}${CM}/${CY}${CM}${CD}
TARFILES="
${EXPNIAG_FILES}
"
NEXTCYC=$(${NDATE} ${CYCINC} ${CDATE})
EXPNIAG_CYC=${EXPNIAG_CYC}
EXPREC=${RECDIR}/${EXP}_${FIELD}
EXPSTATUS=${EXPNIAG_TMP_STATUS}
EOF

echo "${CDATE}: ONGOING" > ${EXPNIAG_TMP_STATUS}
/apps/slurm/default/bin/sbatch sbatch_niag2hpss_cycle.sh
ERR=$?
if [ ${ERR} -ne 0 ]; then
    echo "Submittimg sbatch job failed  at ${CDATE}"
    exit ${ERR}
fi
        fi # SUCCESSFUL
    fi # Wait to next cycle
done # Field
done # EXP
