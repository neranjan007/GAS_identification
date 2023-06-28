version 1.0

task fastqc_task {
    meta{
        description: "FASTQC check on fastq files"
    }

    input{
        #task inputs
        File read1
        File read2
        String docker = "staphb/fastqc:0.11.9"
        Int cpu = 4
        Int memory = 1
    }

    String base_r1 = basename(read1, '.fastq.gz')
    String base_r2 = basename(read2, '.fastq.gz')

    command <<<
        mkdir fastqc_out
        fastqc ~{read1} ~{read2} -t ~{cpu} -o fastqc_out
        fastqc -v | cut -d " " -f 2 > FASTQC_VERSION
        echo ~{base_r1}
        echo ~{base_r2}
    >>>

    output{
        #task outputs
        File r1_fastqc = "fastqc_out/~{base_r1}_fastqc.html"
        File r2_fastqc = "fastqc_out/~{base_r2}_fastqc.html"
    }

    runtime{
        #runtime environment
        docker: "~{docker}"
        memory: "~{memory} GB"
        cpu: cpu
        disks: "local-disk 10 SSD"
        preemptible: 0
    }
}
