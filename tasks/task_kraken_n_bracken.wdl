version 1.0 

task kraken_n_bracken_task{
    meta{
        description: "taxonomic assignment of metagenomics sequencing reads"
    }

    input{
        File read1
        File read2
        String samplename
        File kraken2_db
        Int? bracken_read_len = 100
        Int? bracken_threshold = 10
        String? min_hit_groups = 3
        String docker = "kincekara/kraken-bracken:k2.1.2-b2.8"
        Int? memory = 32
        Int cpu = 4
    }

    command <<<
        # decompress the Kraken2 db
        mkdir db
        tar -I pigz -C ./db/ -xvf ~{kraken2_db}

        # kraken run
        kraken2 \
            --db ./db/ \
            --threads ~{cpu} \
            --gzip-compressed \
            --minimum-hit-groups ~{min_hit_groups} \
            --report-minimizer-data \
            --paired ~{read1} ~{read2} \
            --report ~{samplename}.kraken.report.txt 
        
        # run braken
        bracken \
            -d ./db/ \
            -i ~{samplename}.kraken.report.txt \
            -o ~{samplename}.bracken.txt \
            -r ~{bracken_read_len} \
            -l S \
            -t ~{bracken_threshold}
        
        # filter report
        awk '{if ($NF >= 0.01){print}}' ~{samplename}.bracken.txt > ~{samplename}.bracken.filtered.txt
        # top taxon
        sort -t$'\t' -k7 -nr ~{samplename}.bracken.txt | awk -F "\t" 'NR==1 {print $1}' > TAXON 
        # Pecentage
        sort -t$'\t' -k7 -nr ~{samplename}.bracken.txt | awk -F "\t" 'NR==1 {printf "%.2f\n", $NF*100}' > RATIO
        # Taxonomy id
        sort -t$'\t' -k7 -nr ~{samplename}.bracken.txt | awk -F "\t" 'NR==1 {print $2}' > ~{samplename}.taxid.txt 
        # Genus
        sort -t$'\t' -k7 -nr ~{samplename}.bracken.txt | awk 'NR==1 {print $1}' > GENUS 

    >>>

    output{
        File kraken2_report = "~{samplename}.kraken.report.txt"
        File bracken_report = "~{samplename}.bracken.txt"
        File bracken_report_filter = "~{samplename}.bracken.filtered.txt"
        File bracken_taxid = "~{samplename}.taxid.txt"
        Float bracken_taxon_ratio = read_float("RATIO")
        String bracken_taxon = read_string("TAXON")
        String bracken_genus = read_string("GENUS")

    }

    runtime {
        docker: "~{docker}"
        memory: "~{memory} GB"
        cpu: cpu
        disks: "local-disk 100 SSD"
        preemptible: 0
    }
}