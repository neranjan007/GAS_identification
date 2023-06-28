version 1.0

task emmtypingtool {
    meta{
        description: "emm-typing of Streptococcus pyogenes M serotypes"
    }

    input{
        File read1
        File read2
        String samplename
        String docker = "staphb/emmtypingtool:0.0.1"
        Int cpu = 1
    }

    command <<<
        emm_typing.py \
            -m /db \
            -1 ~{read1} \
            -2 ~{read2} \
            -o output_dir 
        
        grep "version" output_dir/*.results.xml | sed -n 's/.*version="\([^"]*\)".*/\1/p' | tee VERSION
        grep "Final_EMM_type" output_dir/*.results.xml | sed -n 's/.*value="\([^"]*\)".*/\1/p' | tee EMM_type
        mv output_dir/*.results.xml ~{samplename}.emmtypingtool.xml
    >>>

    output {
        String emmtypingtool_emm_type = read_string("EMM_type")
        File emmtypingtool_results_xml = "~{samplename}.emmtypingtool.xml"
        String emmtypingtool_version = read_string("VERSION")
        String emmtypingtool_docker = docker
    }

    runtime {
        docker: "~{docker}"
        memory: "8 GB"
        cpu: cpu
        disks: "local-disk 50 SSD"
        preemptible: 0
    } 

}