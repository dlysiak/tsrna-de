#!/usr/bin/env nextflow

/*===============================================
Split SAM file by feature type and convert to BAM
===============================================*/

process SAM_SPLIT_AND_SAM2BAM {

    input:
    path samfile

    output:
    path("*ncRNAs.bam"), emit: bam_ncRNA
    path("*tRNAs.bam"), emit: bam_tRNA
    //path("*.bam"), emit: bams

    script:
    """
    SAM-split-and-convert-to-BAM.sh ${samfile} > SAM_split-and-SAM2BAM.log
    """
}