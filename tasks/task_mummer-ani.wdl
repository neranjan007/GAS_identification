version 1.0

task mummerANI_task{
    meta{
        description: "identify ANI of Streptococcus_pyogenes"
    }

    input{
        File assembly
        File? ref_genome
        String samplename
        Float mash_filter = 0.9
        String docker = "neranjan007/mummer:4.0.0-ANI-gbs2"
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
        
        # CHECK FOR A NEARLY BLANK TSV (ONLY HEADER LINE), mean sample did not surpass mash-filter and thus no ANI was run
        LINE_COUNT_OUTPUT_TSV=$(wc -l ~{samplename}.ani-mummer.out.tsv | cut -d ' ' -f 1)
        echo "Number of lines in output TSV is: ${LINE_COUNT_OUTPUT_TSV}"
        echo "Number of lines is ${LINE_COUNT_OUTPUT_TSV}" ${LINE_COUNT_OUTPUT_TSV}
        if [[ ${LINE_COUNT_OUTPUT_TSV} -eq 1 ]]; then
            echo "~{samplename} did not surpass the minimum mash genetic distance filter, thus ANI was not performed"
            echo "The output TSV only contains the header line"
            # set output variables as 0s or descriptive strings
            echo "0.0" > TOP_ANI
            echo "0.0" > TOP_PERCENT_ANI
            echo "ANI skipped due to high genetic divergence from reference genomes" > ANI_TOP_SPECIES_MATCH
        # if output TSV has greater than 1 lines, then parse for appropriate outputs
        else
            awk 'NR == 1;  NR > 1 {print $0 | "sort -k5 -nr" }' ~{samplename}.ani-mummer.out.tsv | tee ~{samplename}.ani-mummer.out.sorted.tsv
            ## parse out highest percentBases aligned
            awk 'NR == 2 {print $0 | "cut -f 5" }' ~{samplename}.ani-mummer.out.sorted.tsv | tee TOP_PERCENT_ANI
            echo "highest percent bases aligned is: $(cat TOP_PERCENT_ANI)"
            ## parse out ANI for the highest percentBases aligned
            awk 'NR == 2 {print $0 | "cut -f 3" }' ~{samplename}.ani-mummer.out.sorted.tsv | tee TOP_ANI 

            # have to separate out results for ani_top_species match because user-defined reference genome FASTAs will not be named as they are in RGDv2
            if [[ -z "~{ref_genome}" ]]; then
            ### ref genome is not user-defined, using RGDv2 and FASTA filenames ###
            # Parse out species name from reference fasta filename
            # use percent bases aligned to pull relevant line, cut down to query and ref fasta filenames, sed to remove your query filename, xargs to remove whitespaces & stuff
            # cut on periods to pull out genus_species (in future this will inlcude lineages for Listeria and other sub-species designations)
            # have to create assembly_file_basename bash variable since output TSV does not include full path to assembly file, only filename
                assembly_file_basename=$(basename ~{assembly})
                awk 'NR == 2 {print $0 }' ~{samplename}.ani-mummer.out.sorted.tsv | cut -f 1,2 | sed "s|${assembly_file_basename}||g" | xargs | cut -d '.' -f 3 | tee TOP_SPECIES_ANI
                echo "ANI top species match is: $(cat TOP_SPECIES_ANI)"
            else
                # User defined reference genome: use fasta filename as output string
                basename "${REF_GENOME}" > TOP_SPECIES_ANI
                echo "Reference genome used for ANI is: ${REF_GENOME}" 
            fi
        fi

    >>>

    output {
        File ani_output_tsv = "~{samplename}.ani-mummer.out.tsv"
        Float ani_precent_aligned = read_float("TOP_PERCENT_ANI")
        Float ani_ANI = read_float("TOP_ANI")
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