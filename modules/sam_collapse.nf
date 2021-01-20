#!/usr/bin/env nextflow

/*===============
Collapse SAM file
===============*/

process SAM_COLLAPSE {

    cpus 5

    input:
    path reads

    output:
    path("*Collapsed.sam"), emit: collapsedsam
    path("*tRNAs-almost-mapped.count"), emit: tRNA_almost_mapped_count
    //path("*.log"), emit: collapse_logs

    script:
    """
    SAMcollapse.sh ${reads} ${task.cpus} > SAMcollapse.log
    """
}