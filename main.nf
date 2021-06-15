#!/usr/bin/env nextflow
/*
 *# Author: Paul Donovan 
 *# Email: pauldonovandonegal@gmail.com
*/


nextflow.enable.dsl = 2


// Set default parameters 
params.input_file = null 
params.species = "human"
params.skip = "no"
params.plots = "no"
params.remove = "no"
params.layout = ""
params.input_dir = null
params.output_dir = "Results"
params.min_read_length = 16
params.version = false
params.help = false



// Print message for user
def helpMessage() {
    log.info """\
    
    ========
    tsrna-de
    ========

    Usage: Single file analysis:
    nextflow run main.nf --species mouse --input_file ExampleData/CytC_IP1.fastq.gz --output_dir Results

    Usage: Group comparison analysis:
    nextflow run main.nf --species mouse --input_dir ExampleData --output_dir Results

    Single file analysis mandatory arguments:
    Output directory: ${params.output_dir}
    Input file: ${params.input_file}

    Group comparison analysis mandatory arguments:
    Output directory: ${params.output_dir}
    Input directory of files (/path/to/files): ${params.input_dir}
    

    Other arguments:
    Species (human/mouse/rat): ${params.species}
    Minimum read length: ${params.min_read_length}
    Print help" ${params.help}
    """
}


// Pipeline version
version="Version:  tsrna-de 0.1"


// Print message for user
def versionMessage() {
    log.info """\
    ${version}
    """
}

// Show help message and quit
if (params.help) {
    helpMessage()
    versionMessage()
    exit 0
}


// Show version and quit
if (params.version) {
    versionMessage()
    exit 0
}


// Input parameter error catching
if(!params.input_file && !params.input_dir){
    exit 1, "Error: No input provided. Provide either --input_file or --input_dir to pipeline"
}
if(params.input_dir && !params.layout){
    exit 1, "Error: No --layout file provided. See README for an example"
}
if( params.input_file && params.input_dir){
    exit 1, "Error: Conflicting inputs. Cannot supply both single FASTQ file and FASTQ input directory"
}
//if [[ "$outDir" == */ ]]; then # If outDir has a trailing slash, remove
//	outDir=$(echo "${outDir::-1}")
//fi


// Load modules (these inherit the params above if the default params are also declared in the modules)
include { PREPARE_TRNA_GTF } from './modules/prepare_gtf'
include { FASTQC } from './modules/fastqc'
include { MULTIQC } from './modules/multiqc'
include { MAKE_STAR_DB } from './modules/star_genome-generate'
include { TRIM_READS } from './modules/trim_galore'
include { STAR_ALIGN } from './modules/star_align'
include { SAM_COLLAPSE } from './modules/sam_collapse'
include { SAM_SPLIT_AND_SAM2BAM } from './modules/sam_split_and_sam2bam'
include { FEATURE_COUNT_NCRNA } from './modules/count_features_ncrna'
include { FEATURE_COUNT_TRNA } from './modules/count_features_trna'
include { TSRNA_INDIVIDUAL_COUNT } from './modules/tsrna_counter'
include { TSRNA_DESEQ } from './modules/tsrna_deseq2'


workflow {
    main:
        // Define channels
        ncRNA_gtf = Channel.fromPath("$projectDir/DBs/${params.species}_ncRNAs_relative_cdhit.gtf")
        fastq_channel = Channel.fromPath( ["$params.input_dir/*.fastq.gz", "$params.input_dir/*.fq.gz"] )
        //fastq_channel.view()
        PREPARE_TRNA_GTF(params.species)
        //PREPARE_TRNA_GTF.out.tRNA_gtf.view()
        //DKL FASTQC(fastq_channel)
        //DKL MULTIQC(FASTQC.out.collect())
        TRIM_READS(fastq_channel, "$params.min_read_length")
        //TRIM_READS.out.trimmed_reads.view()
        MAKE_STAR_DB("$projectDir/DBs/${params.species}_tRNAs-and-ncRNAs_relative_cdhit.fa")  // Run process to generate DB
	//daria added below line for lookalikes instead of *_tRNA-and-ncRNA_relative_cdhit.fa
        //MAKE_STAR_DB("$projectDir/DBs/${params.species}_tRNAs-and-ncRNAs-and-lookalikes.fa") // Run process to generate DB by Daria
        STAR_ALIGN(TRIM_READS.out.trimmed_reads, MAKE_STAR_DB.out.star_index)
        //STAR_ALIGN.out.sam.view()
        SAM_COLLAPSE(STAR_ALIGN.out.sam)
        // I should probably output the above as BAM and every other step
        //SAM_COLLAPSE.out.collapsedsam.view()
        SAM_SPLIT_AND_SAM2BAM(SAM_COLLAPSE.out.collapsedsam)
        FEATURE_COUNT_TRNA(SAM_SPLIT_AND_SAM2BAM.out.bam_tRNA, PREPARE_TRNA_GTF.out.tRNA_gtf)
        TSRNA_INDIVIDUAL_COUNT(SAM_SPLIT_AND_SAM2BAM.out.bam_tRNA, PREPARE_TRNA_GTF.out.tRNA_gtf)
        //PREPARE_TRNA_GTF.out.tRNA_gtf.view()
        //TSRNA_DESEQ("$launchDir/${params.layout}", TSRNA_INDIVIDUAL_COUNT.out.tsRNA_individual_counts.collect())
        TSRNA_DESEQ("${params.layout}", TSRNA_INDIVIDUAL_COUNT.out.tsRNA_individual_counts.collect())



}

