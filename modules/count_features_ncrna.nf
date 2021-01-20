#!/usr/bin/env nextflow

/*=================================
Count ncRNA reads using featureCount
=================================*/

process FEATURE_COUNT_NCRNA {

    tag "$bamfile.simpleName"

    input:
    file gtf
    file bamfile

    output:
    path("*.fcount"), emit: fcounts
    path("*.count"), emit: counts
   
    shell:
    '''
    featureCounts \\
        -T !{task.cpus} \\
        -a !{gtf} \\
        -o !{bamfile}.fcount \\
        !{bamfile}
    FCount2Count.sh !{bamfile}.fcount
    '''
}