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

EXP=$1
FIELD=$2

NCP="/bin/cp -r"

[[ ! -d ${RECDIR} ]] && mkdir -p ${RECDIR}
#for EXP in ${EXPS}; do
#for FIELD in ${FIELDS};do
EXPNIAG=${TOPNIAG}/${EXP}/${FIELD}/	
EXPHPSS=${TOPHPSS}/${EXP}/${FIELD}/

EXPNIAG_CYC=${EXPNIAG}/toHPSS/CYCLE.info
CDATE=$(cat ${EXPNIAG_CYC})
#if [ ${CDATE} -gt 2020072618 ]; then
#    exit 0
#fi

EXPGLBUS_REC=${EXPNIAG}/${CDATE}/Globus_o2n_${CDATE}.record
if [ -f ${EXPGLBUS_REC} ]; then
    EXPNIAG_TMP=${EXPNIAG}/toHPSS/tmp/${CDATE}
    [[ ! -d ${EXPNIAG_TMP} ]] && mkdir -p ${EXPNIAG_TMP}
    EXPNIAG_TMP_STATUS=${EXPNIAG_TMP}/N2H.status
    if ( grep "${CDATE}: ONGOING" ${EXPNIAG_TMP_STATUS} ); then
        echo "${EXP}-${FIELD} at ${CDATE} is ongoing and wait."
	exit 0
    elif ( grep "${CDATE}: FAILED" ${EXPNIAG_TMP_STATUS} ); then
        echo "${EXP}-${FIELD} at ${CDATE} failed and wait."
	exit 0
    elif ( grep "${CDATE}: SUCCEEDED" ${EXPNIAG_TMP_STATUS} ); then
        echo "${EXP}-${FIELD} at ${CDATE} already completed and check why CDATE is not updated."
	exit 0
    fi

    if ( grep SUCCESSFUL ${EXPGLBUS_REC} ); then
	cd ${EXPNIAG}/${CDATE}
	EXPNIAG_FILES=$(ls *.tar)

	if [ -z "${EXPNIAG_FILES}" ]; then
	    echo "No tar files found at ${CDATE} ${EXP}-${FIELD}"
	    echo "Exit for now..."
            echo "${CDATE}: FAILED" > ${EXPNIAG_TMP_STATUS}
	    exit 100
	fi

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

/apps/slurm_niagara/default/bin/sbatch sbatch_niag2hpss_cycle.sh
        ERR=$?
        if [ ${ERR} -ne 0 ]; then
            echo "Submitting sbatch job failed  at ${CDATE}"
            echo "${CDATE}: FAILED" > ${EXPNIAG_TMP_STATUS}
            exit ${ERR}
        else
            echo "${CDATE}: ONGOING" > ${EXPNIAG_TMP_STATUS}
        fi
    else
        echo "Cannot find SUCCESSFUL in the log at${EXP}-${FIELD} at ${CDATE} and wait"
        echo "${CDATE}: FAILED" > ${EXPNIAG_TMP_STATUS}
        exit 100
    fi # SUCCESSFUL
else
    echo "${EXP}-${FIELD} at ${CDATE} is not ready yet and wait"
    exit 0
fi # Wait to next cycle
exit 0
