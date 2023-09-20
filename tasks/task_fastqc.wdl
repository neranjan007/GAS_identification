version 1.0

task fastqc_task {
    meta{
        description: "FASTQC check on fastq files"
    }

    input{
        #task inputs
        File read1
        File read2
        String docker = "neranjan007/fastqc:0.11.9_plus"
        Int cpu = 4
        Int memory = 1
    }

    String base_r1 = basename(read1, '.fastq.gz')
    String base_r2 = basename(read2, '.fastq.gz')

    command <<<
        expected_ungapped_length=1797889
        mkdir fastqc_out
        fastqc ~{read1} ~{read2} -t ~{cpu} -o fastqc_out
        fastqc -v | cut -d " " -f 2 > FASTQC_VERSION
        echo ~{base_r1}
        echo ~{base_r2}

        zcat ~{read1} | fastq-scan | jq .qc_stats.read_total > TOTAL_R1_READS
        zcat ~{read1} | fastq-scan | jq .qc_stats.total_bp > TOTAL_R1_BASES
        zcat ~{read1} | fastq-scan >> r1.json 
        r1_no_bases=$(jq -r '.qc_stats.total_bp' r1.json)
        echo "$r1_no_bases" > R1_NO_BASES 
        zcat ~{read2} | fastq-scan >> r2.json
        r2_no_bases=$(jq -r '.qc_stats.total_bp' r2.json)
        total_no_bases=$(expr $r1_no_bases + $r2_no_bases)

        echo "$total_no_bases" > TOTAL_NO_BASES
        echo "$expected_ungapped_length" > EXP_LENGTH

        cal_coverage=`expr $total_no_bases / $expected_ungapped_length`
        echo $cal_coverage
        echo "$cal_coverage" > COVERAGE 
    >>>

    output{
        #task outputs
        File r1_fastqc = "fastqc_out/~{base_r1}_fastqc.html"
        File r2_fastqc = "fastqc_out/~{base_r2}_fastqc.html"
        String r1_read_count = read_string("TOTAL_R1_READS")
        String r1_no_bases = read_string("R1_NO_BASES")
        String total_no_bases = read_string("TOTAL_NO_BASES")
        String coverage = read_string("COVERAGE")
        String exp_length = read_string("EXP_LENGTH")
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
