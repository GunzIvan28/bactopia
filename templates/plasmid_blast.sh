#!/bin/bash
set -e
set -u

LOG_DIR="!{task.process}"
mkdir -p ${LOG_DIR}

echo "# Timestamp" > ${LOG_DIR}/!{task.process}.versions
date --iso-8601=seconds >> ${LOG_DIR}/!{task.process}.versions

echo "# blastn Version" >> ${LOG_DIR}/!{task.process}.versions
blastn -version >> ${LOG_DIR}/!{task.process}.versions 2>&1

echo "# Parallel Version" >> ${LOG_DIR}/!{task.process}.versions
parallel --version >> ${LOG_DIR}/!{task.process}.versions 2>&1

file_size=`gzip -dc !{genes} | wc -c`
block_size=$(( file_size / !{task.cpus} / 2 ))
gzip -cd !{genes} | \
parallel --gnu --plain -j !{task.cpus} --block ${block_size} --recstart '>' --pipe \
blastn -db !{blastdb} \
       -outfmt 15 \
       -task blastn \
       -evalue 1 \
       -max_target_seqs !{params.max_target_seqs} \
       -perc_identity !{params.perc_identity} \
       -qcov_hsp_perc !{params.qcov_hsp_perc} \
       -query - > !{sample}-plsdb.txt

if [[ !{params.compress} == "true" ]]; then
    pigz --best -n -p !{task.cpus} !{sample}-plsdb.txt
fi

if [ "!{params.skip_logs}" == "false" ]; then 
    cp .command.err ${LOG_DIR}/!{task.process}.err
    cp .command.out ${LOG_DIR}/!{task.process}.out
    cp .command.sh ${LOG_DIR}/!{task.process}.sh || :
    cp .command.trace ${LOG_DIR}/!{task.process}.trace || :
else
    rm -rf ${LOG_DIR}/
fi
