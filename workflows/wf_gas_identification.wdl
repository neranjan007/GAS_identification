version 1.0

import "../tasks/task_fastqc.wdl" as fastqc
import "../tasks/task_emmtypingtool.wdl" as emmtyping_task
import "../tasks/task_kraken_n_bracken.wdl" as kraken_n_bracken
import "../tasks/task_trimmomatic.wdl" as trimmomatic
import "../tasks/task_spades.wdl" as spades
import "../tasks/task_rmlst.wdl" as rmlst
import "../tasks/task_emmtyper.wdl" as emmtyper
import "../tasks/task_mummer-ani.wdl" as ani
import "../tasks/task_quast.wdl" as quast

workflow GAS_identification_workflow{
    input{
        File R1
        File R2
        String samplename
        String? emmtypingtool_docker_image
        File? referance_genome
    }

    # tasks and/or subworkflows to execute
    call fastqc.fastqc_task as rawfastqc_task{
        input:
            read1 = R1,
            read2 = R2 
    }

    call trimmomatic.trimmomatic_task{
        input:
            read1 = R1,
            read2 = R2
    }

    call fastqc.fastqc_task as trimmedfastqc_task{
        input:
            read1 = trimmomatic_task.read1_paired,
            read2 = trimmomatic_task.read2_paired
    }

    call emmtyping_task.emmtypingtool{
        input:
            read1 = trimmomatic_task.read1_paired,
            read2 = trimmomatic_task.read2_paired,
            samplename = samplename,
            docker = emmtypingtool_docker_image
    }


    call kraken_n_bracken.kraken_n_bracken_task as raw_kraken_n_bracken_task{
        input:
            read1 = trimmomatic_task.read1_paired,
            read2 = trimmomatic_task.read2_paired,
            samplename = samplename        
    }

    call spades.spades_task{
        input:
            read1 = trimmomatic_task.read1_paired,
            read2 = trimmomatic_task.read2_paired,
            samplename = samplename
    }

    call quast.quast_task{
        input:
            assembly = spades_task.scaffolds,
            samplename = samplename
    }

    call rmlst.rmlst_task{
        input:
            scaffolds = spades_task.scaffolds
    }

    call emmtyper.emmtyper_task{
        input:
            assembly = spades_task.scaffolds,
            samplename = samplename
    }

    call ani.mummerANI_task{
        input:
            assembly = spades_task.scaffolds,
            ref_genome = referance_genome,
            samplename = samplename
    }

    call kraken_n_bracken.kraken_n_bracken_task as trimmed_kraken_n_bracken_task{
        input:
            read1 = trimmomatic_task.read1_paired,
            read2 = trimmomatic_task.read2_paired,
            samplename = samplename
    }

    output{
        File FASTQC_raw_R1 = rawfastqc_task.r1_fastqc
        File FASTQC_raw_R2 = rawfastqc_task.r2_fastqc
        # Streptococcus pyogenes Typing
        String? emmtypingtool_emm_type = emmtypingtool.emmtypingtool_emm_type
        File? emmtypingtool_results_xml = emmtypingtool.emmtypingtool_results_xml
        String? emmtypingtool_version = emmtypingtool.emmtypingtool_version
        String? emmtypingtool_docker = emmtypingtool.emmtypingtool_docker
        # kraken2 Bracken 
        String Bracken_top_taxon_rawReads = raw_kraken_n_bracken_task.bracken_taxon
        Float Bracken_taxon_ratio_rawReads = raw_kraken_n_bracken_task.bracken_taxon_ratio
        String Bracken_top_genus_rawReads = raw_kraken_n_bracken_task.bracken_genus
        # Trimmed read qc
        File FASTQC_Trim_R1 = trimmedfastqc_task.r1_fastqc
        File FASTQC_Trim_R2 = trimmedfastqc_task.r2_fastqc
        #File Spades_scaffolds = spades_task.scaffolds
        # quast
        File QUAST_report = quast_task.quast_report
        Int QUAST_genome_length = quast_task.genome_length
        Int QUAST_no_of_contigs = quast_task.number_contigs
        Int QUAST_n50_value = quast_task.n50_value
        Float QUAST_gc_percent = quast_task.gc_percent
        # kraken2 Bracken after trimming
        String Bracken_top_taxon = trimmed_kraken_n_bracken_task.bracken_taxon
        Float Bracken_taxon_ratio = trimmed_kraken_n_bracken_task.bracken_taxon_ratio
        String Bracken_top_genus = trimmed_kraken_n_bracken_task.bracken_genus
        File Bracken_report_sorted = trimmed_kraken_n_bracken_task.bracken_report_sorted
        # rMLST 
        String rMLST_TAXON = rmlst_task.taxon
        # emmTyper 
        File emmtyper_results = emmtyper_task.emmtyper_results
        String emmtyper_emmtype = emmtyper_task.emmtype
        # ani
        Float ani_precent_aligned = mummerANI_task.ani_precent_aligned
        Float ani_percent = mummerANI_task.ani_ANI
    }

}