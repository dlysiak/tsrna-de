#!/usr/bin/env nextflow

/*======================
Run STAR genome generate
======================*/


process MAKE_STAR_DB {

    input:
    path fasta

    output:
    path "star_db", emit: star_index 

    """
    mkdir -p star_db
    STAR \\
        --runMode genomeGenerate \\
        --genomeDir star_db/ \\
        --genomeFastaFiles $fasta \\
	--runThreadN $task.cpus \\
	// Daria modification below
        --genomeSAindexNbases 12 \\
	--genomeSAsparseD 3 \\
        --genomeChrBinNbits 14 \\
        

	 
    STAR --version | sed -e "s/STAR_//g" > STAR.version.txt
    """

}
