#!/bin/bash --login
#SBATCH -J n2hpss_cycle
#SBATCH -A niagara
#SBATCH -n 1
#SBATCH -t 23:59:00
#SBATCH -p service
#SBATCH -D ./
#SBATCH -o ./niag2hpss_cycle.out
#SBATCH -e ./niag2hpss_cycle.out

set -x
source config_niag2hpss_cycle
module load hpss

ICNT=0
hsi "mkdir -p ${EXPHPSS_DIR}"
ERR=$?
ICNT=$((${ICNT}+${ERR}))

for TARFILE in ${TARFILES}; do
    echo "put ${EXPNIAG_DIR}/${TARFILE} : ${EXPHPSS_DIR}/${TARFILE}"
    hsi "put ${EXPNIAG_DIR}/${TARFILE} : ${EXPHPSS_DIR}/${TARFILE}"
    ERR=$?
    ICNT=$((${ICNT}+${ERR}))
done

if [ ${ICNT} -ne 0 ]; then
    echo "N2H failed at ${CDATE}"
    echo "${CDATE}: FAILED at $(date)" >> ${EXPREC}
    echo "${CDATE}: FAILED" > ${EXPSTATUS}
    exit ${ICNT}
else
    echo "N2H succeeded at ${CDATE}"
    echo "${CDATE}: SUCCEEDED at $(date)" >> ${EXPREC}
    echo "${CDATE}: SUCCEEDED" > ${EXPSTATUS}
    echo ${NEXTCYC} > ${EXPNIAG_CYC}
    rm -rf ${EXPNIAG_DIR}/*.tar
    #echo "TEST: ${EXPNIAG_DIR}"
    #echo "TEST: ${EXPREC}"
    #echo "TEST: ${EXPNIAG_CYC}"
    exit ${ICNT}
fi
exit ${ICNT}
