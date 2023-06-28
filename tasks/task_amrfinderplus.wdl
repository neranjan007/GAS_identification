version 1.0

task amrfinderplus_task{
    meta{
        description: "identify acquired antimicrobial resistance genes"
    }

    input{
        File assembly
        String samplename
        File amr_db
        String? organism
        Float? minid
        Float? mincov
        String docker = "kincekara/amrfinder:3.10.40"
        Int cpu = 4

        # Parameters 
        # --indent_min Minimum DNA %identity [0-1]; default is 0.9 (90%) or curated threshold if it exists
        # --mincov Minimum DNA %coverage [0-1]; default is 0.5 (50%)
    }

    command <<<
        # version
        amrfinder --version | tee AMRFINDER_VERSION 
        mkdir db
        # decompress amrfinder db
        tar -C ./db/ -xvf ~{amr_db}
        
        if [[ "~{organism}" == *"Streptococcus"*"pyogenes"* ]]; then
            amrfinder_organism="Streptococcus_pyogenes"
        else 
            echo "Either Bracken predicted taxon is not supported by NCBI-AMRFinderPlus or the user did not supply an organism as input."
            echo "Skipping the use of amrfinder --organism optional parameter."
        fi

        # checking bash variable
        echo "amrfinder_organism is set to:" ${amrfinder_organism}

        # if amrfinder_organism variable is set, use --organism flag, otherwise do not use --organism flag
        if [[ -v amrfinder_organism ]] ; then
            # always use --plus flag, others may be left out if param is optional and not supplied 
            # send STDOUT/ERR to log file for capturing database version
            amrfinder --plus \
                -d ./db/ \
                --organism ${amrfinder_organism} \
                ~{'--name ' + samplename} \
                ~{'--nucleotide ' + assembly} \
                ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
                ~{'--threads ' + cpu} \
                ~{'--coverage_min ' + mincov} \
                ~{'--ident_min ' + minid} 2>&1 | tee amrfinder.STDOUT-and-STDERR.log
        else 
            # always use --plus flag, others may be left out if param is optional and not supplied 
            # send STDOUT/ERR to log file for capturing database version
            amrfinder --plus \
                -d ./db/ \
                ~{'--name ' + samplename} \
                ~{'--nucleotide ' + assembly} \
                ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
                ~{'--threads ' + cpu} \
                ~{'--coverage_min ' + mincov} \
                ~{'--ident_min ' + minid} 2>&1 | tee amrfinder.STDOUT-and-STDERR.log
        fi  

        # Element Type possibilities: AMR, STRESS, and VIRULENCE 
        # create headers for 3 output files; tee to 3 files and redirect STDOUT to dev null so it doesn't print to log file
        head -n 1 ~{samplename}_amrfinder_all.tsv | tee ~{samplename}_amrfinder_stress.tsv ~{samplename}_amrfinder_virulence.tsv ~{samplename}_amrfinder_amr.tsv >/dev/null
    >>>
    
    output{
        File amrfinderplus_all_report = "~{samplename}_amrfinder_all.tsv"
        File amrfinderplus_amr_report = "~{samplename}_amrfinder_amr.tsv"
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