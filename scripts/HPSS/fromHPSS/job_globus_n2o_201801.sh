#!/bin/bash
#SBATCH -J 201801glbus_h2n
#SBATCH -A niagara
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o /collab1/data/Bo.Huang/dataTransfer/AeroReanl/ChgresGDAS/glbus_h2n_201801.out
#SBATCH -e /collab1/data/Bo.Huang/dataTransfer/AeroReanl/ChgresGDAS/glbus_h2n-201801.out

module load globus-cli

set -x

SDATE=$(cat SDATE_201801.info)  #2020071300
EDATE=$(cat EDATE_201801.info)  #2020071318
HRS="00 06 12 18"
CYCINC=24
NDATE="/home/Bo.Huang/Projects/AeroReanl/bin/ndate"
CURDIR="/home/Bo.Huang/Projects/AeroReanl/scripts/HPSS/fromHPSS"

NIAGEP=1bfd8a79-52b2-4589-88b2-0648e0c0b35d
ORIONEP=2cf2c281-cafc-4b20-900b-45abeb042854

CASE_GDAS="C96"
CASE_ENKF="C96"
NMEMSGRPS="01-40"
GFSVER=v14
NIAGDIR=/collab1/data/Bo.Huang/dataTransfer/AeroReanl/ChgresGDAS/chgres-${GFSVER}
ORIONDIR=/work/noaa/rstprod/bohuang/DataTransfer/FromNiag/AeroReanl/ChgresGDAS/chgres-${GFSVER}
RECORD=${CURDIR}/record_glbus_n2o.log
LOGDIR=${NIAGDIR}/logs

[[ ! -d ${LOGDIR} ]] && mkdir -p ${LOGDIR}

CDATE=${SDATE}
while [ ${CDATE} -le ${EDATE} ]; do
    echo ${CDATE}
    ICNT=0
    CY=${CDATE:0:4}
    CM=${CDATE:4:2}
    CD=${CDATE:6:2}
    CYMD=${CDATE:0:8}
    #CH=${CDATE:8:2}
    NIAGGDAS=${NIAGDIR}/GDAS_CHGRES_NC_${CASE_GDAS}/${CY}/${CY}${CM}/${CY}${CM}${CD}
    NIAGENKF=${NIAGDIR}/ENKFGDAS_CHGRES_NC_${CASE_ENKF}/${CY}/${CY}${CM}/${CY}${CM}${CD}
    ORIONGDAS=${ORIONDIR}/GDAS_CHGRES_NC_${CASE_GDAS}/${CY}/${CY}${CM}/${CY}${CM}${CD}
    ORIONENKF=${ORIONDIR}/ENKFGDAS_CHGRES_NC_${CASE_ENKF}/${CY}/${CY}${CM}/${CY}${CM}${CD}

    GINPUT=${LOGDIR}/GlobusInput.out
    GID=${LOGDIR}/GlobusID_${CYMD}.out
    [[ -f ${GINPUT} ]] && rm -rf ${GINPUT}
    for CH in 00 06 12 18; do
        NIAGFILE=${NIAGGDAS}/gdas.${CYMD}${CH}.${CASE_GDAS}.NC.tar
        ORIONFILE=${ORIONGDAS}/gdas.${CYMD}${CH}.${CASE_GDAS}.NC.tar
	echo "${NIAGFILE} ${ORIONFILE}" >> ${GINPUT}

        NIAGFILE=${NIAGENKF}/enkfgdas.${CYMD}${CH}.${CASE_ENKF}.NC.${NMEMSGRPS}.tar
        ORIONFILE=${ORIONENKF}/enkfgdas.${CYMD}${CH}.${CASE_ENKF}.NC.${NMEMSGRPS}.tar
	echo "${NIAGFILE}    ${ORIONFILE}" >> ${GINPUT}
    done 

    #globus transfer ${NIAGEP}:/ ${ORIONEP}:/ --batch --label "CLI batch" < ${GINPUT} >& ${GID}
    globus transfer --notify failed,inactive ${NIAGEP}:/ ${ORIONEP}:/  --batch ${GINPUT} >& ${GID}
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))

    GLBUSID=$(tail -n 1 ${GID} | awk '{print $3}')
    globus task wait "${GLBUSID}"
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))

    if [ ${ICNT} -ne 0 ]; then
        echo "Globus n2o failed at ${CDATE} and exit"
	echo "${CDATE}: FAILED" >> ${RECORD}
        exit ${ICNT}
    else
	echo "${CDATE}: SUCCESSFUL" >> ${RECORD}
    fi
    CDATE=$(${NDATE} ${CYCINC} ${CDATE})
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
    if [ ${ICNT} -ne 0 ]; then
        echo "Continuing to next cycle failed  at ${CDATE}"
	exit ${ICNT}
    fi
done

exit ${ICNT}

