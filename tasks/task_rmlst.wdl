version 1.0

task rmlst_task{
    meta{
        description: "rMLST typing from pubMLST"
    }    

    input{
        File scaffolds
        String docker = "neranjan007/jq:1.6.2"
        Int cpu = 1
        Int memory = 2
    } 

    command <<<
        (echo -n '{"base64":true,"details":true,"sequence": "'; base64 ~{scaffolds}; echo '"}') | curl -s -H "Content-Type: application/json" -X POST "http://rest.pubmlst.org/db/pubmlst_rmlst_seqdef_kiosk/schemes/1/sequence" -d @- > rmlst.json
        taxon=$(jq -r '.taxon_prediction[0].taxon'  rmlst.json)
        echo "$taxon" > TAXON
    >>>

    output{
        String taxon = read_string("TAXON")
    }

    runtime{
        docker: "~{docker}"
        memory: "~{memory} GB"
        cpu: cpu
        disks: "local-disk 50 SSD"
        preemptible: 0
    }
}
