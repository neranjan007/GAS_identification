version 1.0

task trimmomatic_task{
    meta{
        description: "Trimmomatic trimming of fastw files"
    }

    input{
        #task inputs
        File read1
        File read2
        Int minlen = 50
        Int window_size = 10
        Int required_quality = 30
        String docker = "staphb/trimmomatic:0.39"
        Int cpu = 8
        Int memory = 10
    }

    String samplename_r1 = basename(read1, '.fastq.gz')
    String samplename_r2 = basename(read2, '.fastq.gz')

    command <<<
        echo "~{read1}"
        echo "~{samplename_r1}"
        echo "~{samplename_r2}"
        trimmomatic PE \
            -threads ~{cpu} \
            "~{read1}" "~{read2}" \
            "paired_~{samplename_r1}.fastq.gz" "unpaired_~{samplename_r1}.fastq.gz" \
            "paired_~{samplename_r2}.fastq.gz" "unpaired_~{samplename_r2}.fastq.gz" \
            ILLUMINACLIP:/Trimmomatic-0.39/adapters/TruSeq3-PE.fa:2:30:10:8:TRUE \
            LEADING:30 TRAILING:30 \
            SLIDINGWINDOW:~{window_size}:~{required_quality} MINLEN:~{minlen} &> trim.stats.txt        

        # removes the brackets from the percentage string
        grep "Both Surviving" trim.stats.txt | awk -F " " ' { print $8 } ' | sed 's/[)(]//g' > serviving_pairs
        grep "Input Read Pairs" trim.stats.txt >  trim.stats-only.txt
    >>>
    
    output{
        File read1_paired = "paired_~{samplename_r1}.fastq.gz"
        File read2_paired = "paired_~{samplename_r2}.fastq.gz"
        File trimed_stats = "trim.stats-only.txt"
        String serviving_read_pairs = read_string("serviving_pairs")
    }

    runtime{
        docker: "~{docker}"
        memory: "~{memory} GB"
        cpu: cpu
        disks: "local-disk 50 SSD"
        preemptible: 0
    }    
}
