version 1.0

task mummerani_task{
    meta{
        description: "identify ANI of Streptococcus_pyogenes"
    }

    input{
        File assembly
        File? ref_genome
        String samplename
        Float mash_filter = 0.9
        String docker = "neranjan007/mummer:4.0.0-ANI-gas"
        Int cpu = 1
    }

    command <<<
        # set the reference genome
        # if not defined by user, then use the ref genome in DB 
        if [[ -z "~{ref_genome}" ]]; then
            # ref genome is not defined. default to DB 
            # BASH variable
            REF_GENOME="$(ls /DB/*.fasta)"
            echo "user did not define a reference genome, defaulting to ref genome in DB"
            echo "REF_GENOME is set to: ${REF_GENOME}"
        else 
            echo "User specified a reference genome, will use this instead of DB "
            REF_GENOME="~{ref_genome}"
            echo "REF_GENOME is set to: ${REF_GENOME}"
        fi

        # call Lee's ani-m.pl script and compare query genome against reference genome
        # first does a mash check on relatedness between 2 genomes. If greater than mash_filter, then run dnadiff
        # --symmetric flag runs ANI on query vs. ref; followed by ref vs. query
        ani-m.pl --symmetric \
            --mash-filter ~{mash_filter} \
            ~{assembly} \
            ${REF_GENOME} | tee ~{samplename}.ani-mummer.out.tsv
    >>>

    output {
        File ani_output_tsv = "~{samplename}.ani-mummer.out.tsv"
    }

    runtime {
        memory: "8 GB"
        cpu: cpu
        docker: docker
        disks: "local-disk 100 SSD"
        preemptible: 0
        maxRetries: 3
    }
}