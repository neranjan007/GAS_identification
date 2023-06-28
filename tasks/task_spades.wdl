version 1.0

task spades_task{
    meta{
        description: "Reads assembly using Spades"
    }

    input{
        #task inputs
        File read1
        File read2
        Int cpu = 8
        String docker = "staphb/spades:3.15.5"
        Int memory = 100
        String samplename
    }

    String samplename_r1 = basename(read1, '_paired.fastq.gz')


    command <<<
        echo ~{read1}
        echo ~{samplename_r1}

        spades.py \
            -1 ~{read1} \
            -2 ~{read2} \
            -t ~{cpu} \
            --careful \
            -o ~{samplename}
    >>>

    output{
        File scaffolds = "~{samplename}/scaffolds.fasta"
    }

    runtime{
        docker: "~{docker}"
        memory: "~{memory} GB"
        cpu: cpu
        disks: "local-disk 50 SSD"
        preemptible: 0
    }
}
