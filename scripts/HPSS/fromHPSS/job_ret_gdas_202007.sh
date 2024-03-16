#!/bin/bash
#SBATCH -J 202007ret_h2n
#SBATCH -A niagara
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH --mem=6g
#SBATCH -D ./
#SBATCH -o /collab1/data/Bo.Huang/dataTransfer/AeroReanl/ChgresGDAS/ret_h2n_202007.out
#SBATCH -e /collab1/data/Bo.Huang/dataTransfer/AeroReanl/ChgresGDAS/ret_h2n_202007.out

module load hpss

set -x

SDATE=2020100100  #2020090100  #2020072500
EDATE=2020103118  #2020093018  #2020083118
echo "${SDATE}" > SDATE_202007.info 
echo "${EDATE}" > EDATE_202007.info 
CYCINC=6
NDATE="/home/Bo.Huang/Projects/AeroReanl/bin/ndate"
CURDIR="/home/Bo.Huang/Projects/AeroReanl/scripts/HPSS/fromHPSS"

CASE_GDAS="C96"
CASE_ENKF="C96"
NMEMSGRPS="01-40"
GFSVER=v15
HPSSDIR=/BMC/fim/5year/MAPP_2018/bhuang/BackupGdas/chgres-${GFSVER}
NIAGDIR=/collab1/data/Bo.Huang/dataTransfer/AeroReanl/ChgresGDAS/chgres-${GFSVER}
RECORD=${CURDIR}/record_gdas_h2n.log

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    echo ${CDATE}
    ICNT=0
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CH=${CDATE:8:2}
    
    HPSSGDAS=${HPSSDIR}/GDAS_CHGRES_NC_${CASE_GDAS}/${CY}/${CY}${CM}/${CY}${CM}${CD}
    HPSSENKF=${HPSSDIR}/ENKFGDAS_CHGRES_NC_${CASE_ENKF}/${CY}/${CY}${CM}/${CY}${CM}${CD}
    NIAGGDAS=${NIAGDIR}/GDAS_CHGRES_NC_${CASE_GDAS}/${CY}/${CY}${CM}/${CY}${CM}${CD}
    NIAGENKF=${NIAGDIR}/ENKFGDAS_CHGRES_NC_${CASE_ENKF}/${CY}/${CY}${CM}/${CY}${CM}${CD}

    [[ ! -d ${NIAGGDAS} ]] && mkdir -p ${NIAGGDAS}
    [[ ! -d ${NIAGENKF} ]] && mkdir -p ${NIAGENKF}
    cd ${NIAGGDAS}
    HPSSFILE=${HPSSGDAS}/gdas.${CDATE}.${CASE_GDAS}.NC.tar
    hsi get ${HPSSFILE}
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))

    cd ${NIAGENKF}
    HPSSFILE=${HPSSENKF}/enkfgdas.${CDATE}.${CASE_ENKF}.NC.${NMEMSGRPS}.tar
    hsi get ${HPSSFILE}
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
    if [ ${ICNT} -ne 0 ]; then
        echo "HSI GET failed at ${CDATE} and exit"
	echo "${CDATE}: FAILED" >> ${RECORD}
        exit ${ICNT}
    else
	echo "${CDATE}: SUCCESSFUL" >> ${RECORD}
    fi
    CDATE=$(${NDATE} ${CYCINC} ${CDATE})
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
    if [ ${ICNT} -ne 0 ]; then
        echo "Continuing to next cycle failed at ${CDATE}"
	exit ${ICNT}
    fi
done

cd ${CURDIR}
/apps/slurm_niagara/default/bin/sbatch job_globus_n2o_202007.sh
ERR=$?
ICNT=$((${ICNT}+${ERR}))
if [ ${ICNT} -ne 0 ]; then
    echo "Submittimg globus failed  at ${CDATE}"
    exit ${ICNT}
fi
exit ${ICNT}

